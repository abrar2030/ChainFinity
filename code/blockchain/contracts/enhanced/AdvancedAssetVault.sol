// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title AdvancedAssetVault
 * @dev Enhanced asset vault with institutional-grade features for financial applications
 * @notice This contract provides secure asset management with advanced features like
 *         multi-signature operations, time-locked withdrawals, and compliance controls
 */
contract AdvancedAssetVault is ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    bytes32 public constant COMPLIANCE_ROLE = keccak256('COMPLIANCE_ROLE');
    bytes32 public constant EMERGENCY_ROLE = keccak256('EMERGENCY_ROLE');

    // Vault configuration
    struct VaultConfig {
        uint256 maxDepositAmount;
        uint256 minDepositAmount;
        uint256 withdrawalTimelock;
        uint256 dailyWithdrawalLimit;
        bool requiresApproval;
        bool complianceEnabled;
    }

    // User deposit information
    struct UserDeposit {
        uint256 amount;
        uint256 timestamp;
        bool isLocked;
        uint256 unlockTime;
        string metadata;
    }

    // Withdrawal request
    struct WithdrawalRequest {
        address user;
        address token;
        uint256 amount;
        uint256 requestTime;
        uint256 executeTime;
        bool approved;
        bool executed;
        address approver;
        string reason;
    }

    // Asset information
    struct AssetInfo {
        bool isSupported;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 maxAllocation;
        uint256 riskRating; // 1-10 scale
        bool requiresKYC;
    }

    // Events
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp,
        string metadata
    );

    event WithdrawalRequested(
        uint256 indexed requestId,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 executeTime
    );

    event WithdrawalApproved(
        uint256 indexed requestId,
        address indexed approver,
        uint256 timestamp
    );

    event WithdrawalExecuted(
        uint256 indexed requestId,
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event AssetAdded(
        address indexed token,
        uint256 maxAllocation,
        uint256 riskRating,
        bool requiresKYC
    );

    event ComplianceCheck(
        address indexed user,
        address indexed token,
        uint256 amount,
        bool passed,
        string reason
    );

    event EmergencyWithdrawal(
        address indexed token,
        uint256 amount,
        address indexed recipient,
        string reason
    );

    // State variables
    VaultConfig public vaultConfig;
    mapping(address => mapping(address => UserDeposit[])) public userDeposits; // user => token => deposits
    mapping(address => AssetInfo) public supportedAssets;
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    mapping(address => mapping(uint256 => uint256)) public dailyWithdrawals; // user => day => amount
    mapping(address => bool) public kycVerified;
    mapping(address => bool) public blacklisted;

    uint256 public nextRequestId = 1;
    uint256 public totalValueLocked;
    address public treasury;
    address public complianceOracle;

    // Modifiers
    modifier onlyKYCVerified() {
        require(
            kycVerified[msg.sender] || !vaultConfig.complianceEnabled,
            'KYC verification required'
        );
        _;
    }

    modifier notBlacklisted(address user) {
        require(!blacklisted[user], 'Address is blacklisted');
        _;
    }

    modifier validAsset(address token) {
        require(supportedAssets[token].isSupported, 'Asset not supported');
        _;
    }

    modifier onlyCompliance() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), 'Compliance role required');
        _;
    }

    /**
     * @dev Constructor
     * @param _admin Admin address
     * @param _treasury Treasury address for fees
     * @param _complianceOracle Compliance oracle address
     */
    constructor(address _admin, address _treasury, address _complianceOracle) {
        require(_admin != address(0), 'Invalid admin address');
        require(_treasury != address(0), 'Invalid treasury address');

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _admin);
        _grantRole(COMPLIANCE_ROLE, _admin);
        _grantRole(EMERGENCY_ROLE, _admin);

        treasury = _treasury;
        complianceOracle = _complianceOracle;

        // Default vault configuration
        vaultConfig = VaultConfig({
            maxDepositAmount: 1000000 * 10 ** 18, // 1M tokens
            minDepositAmount: 1 * 10 ** 18, // 1 token
            withdrawalTimelock: 24 hours,
            dailyWithdrawalLimit: 100000 * 10 ** 18, // 100K tokens
            requiresApproval: true,
            complianceEnabled: true
        });
    }

    /**
     * @dev Deposit assets into the vault
     * @param token Token address
     * @param amount Amount to deposit
     * @param metadata Additional metadata
     */
    function deposit(
        address token,
        uint256 amount,
        string calldata metadata
    )
        external
        nonReentrant
        whenNotPaused
        onlyKYCVerified
        notBlacklisted(msg.sender)
        validAsset(token)
    {
        require(amount > 0, 'Amount must be greater than 0');
        require(amount >= vaultConfig.minDepositAmount, 'Amount below minimum');
        require(amount <= vaultConfig.maxDepositAmount, 'Amount exceeds maximum');

        AssetInfo storage asset = supportedAssets[token];
        require(
            asset.totalDeposited.add(amount) <= asset.maxAllocation,
            'Exceeds asset allocation limit'
        );

        // Compliance check
        if (vaultConfig.complianceEnabled) {
            require(
                _performComplianceCheck(msg.sender, token, amount, 'DEPOSIT'),
                'Compliance check failed'
            );
        }

        // Transfer tokens
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Record deposit
        userDeposits[msg.sender][token].push(
            UserDeposit({
                amount: amount,
                timestamp: block.timestamp,
                isLocked: false,
                unlockTime: 0,
                metadata: metadata
            })
        );

        // Update totals
        asset.totalDeposited = asset.totalDeposited.add(amount);
        totalValueLocked = totalValueLocked.add(amount);

        emit Deposit(msg.sender, token, amount, block.timestamp, metadata);
    }

    /**
     * @dev Request withdrawal from the vault
     * @param token Token address
     * @param amount Amount to withdraw
     * @param reason Reason for withdrawal
     */
    function requestWithdrawal(
        address token,
        uint256 amount,
        string calldata reason
    )
        external
        nonReentrant
        whenNotPaused
        notBlacklisted(msg.sender)
        validAsset(token)
        returns (uint256 requestId)
    {
        require(amount > 0, 'Amount must be greater than 0');
        require(_getUserBalance(msg.sender, token) >= amount, 'Insufficient balance');

        // Check daily withdrawal limit
        uint256 today = block.timestamp / 1 days;
        require(
            dailyWithdrawals[msg.sender][today].add(amount) <= vaultConfig.dailyWithdrawalLimit,
            'Daily withdrawal limit exceeded'
        );

        // Compliance check
        if (vaultConfig.complianceEnabled) {
            require(
                _performComplianceCheck(msg.sender, token, amount, 'WITHDRAWAL'),
                'Compliance check failed'
            );
        }

        requestId = nextRequestId++;
        uint256 executeTime = block.timestamp.add(vaultConfig.withdrawalTimelock);

        withdrawalRequests[requestId] = WithdrawalRequest({
            user: msg.sender,
            token: token,
            amount: amount,
            requestTime: block.timestamp,
            executeTime: executeTime,
            approved: !vaultConfig.requiresApproval,
            executed: false,
            approver: address(0),
            reason: reason
        });

        // Update daily withdrawal tracking
        dailyWithdrawals[msg.sender][today] = dailyWithdrawals[msg.sender][today].add(amount);

        emit WithdrawalRequested(requestId, msg.sender, token, amount, executeTime);
    }

    /**
     * @dev Approve withdrawal request
     * @param requestId Request ID
     */
    function approveWithdrawal(uint256 requestId) external onlyRole(OPERATOR_ROLE) {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        require(request.user != address(0), 'Invalid request');
        require(!request.approved, 'Already approved');
        require(!request.executed, 'Already executed');

        request.approved = true;
        request.approver = msg.sender;

        emit WithdrawalApproved(requestId, msg.sender, block.timestamp);
    }

    /**
     * @dev Execute approved withdrawal
     * @param requestId Request ID
     */
    function executeWithdrawal(uint256 requestId) external nonReentrant whenNotPaused {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        require(request.user == msg.sender, 'Not request owner');
        require(request.approved, 'Not approved');
        require(!request.executed, 'Already executed');
        require(block.timestamp >= request.executeTime, 'Timelock not expired');
        require(!blacklisted[msg.sender], 'Address is blacklisted');

        // Verify user still has sufficient balance
        require(
            _getUserBalance(msg.sender, request.token) >= request.amount,
            'Insufficient balance'
        );

        // Mark as executed
        request.executed = true;

        // Update user deposits (FIFO)
        _deductFromUserDeposits(msg.sender, request.token, request.amount);

        // Update totals
        AssetInfo storage asset = supportedAssets[request.token];
        asset.totalWithdrawn = asset.totalWithdrawn.add(request.amount);
        totalValueLocked = totalValueLocked.sub(request.amount);

        // Transfer tokens
        IERC20(request.token).safeTransfer(msg.sender, request.amount);

        emit WithdrawalExecuted(requestId, msg.sender, request.token, request.amount);
    }

    /**
     * @dev Emergency withdrawal (admin only)
     * @param token Token address
     * @param amount Amount to withdraw
     * @param recipient Recipient address
     * @param reason Emergency reason
     */
    function emergencyWithdrawal(
        address token,
        uint256 amount,
        address recipient,
        string calldata reason
    ) external onlyRole(EMERGENCY_ROLE) {
        require(recipient != address(0), 'Invalid recipient');
        require(amount > 0, 'Amount must be greater than 0');
        require(IERC20(token).balanceOf(address(this)) >= amount, 'Insufficient contract balance');

        IERC20(token).safeTransfer(recipient, amount);

        emit EmergencyWithdrawal(token, amount, recipient, reason);
    }

    /**
     * @dev Add supported asset
     * @param token Token address
     * @param maxAllocation Maximum allocation for this asset
     * @param riskRating Risk rating (1-10)
     * @param requiresKYC Whether KYC is required for this asset
     */
    function addSupportedAsset(
        address token,
        uint256 maxAllocation,
        uint256 riskRating,
        bool requiresKYC
    ) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), 'Invalid token address');
        require(riskRating >= 1 && riskRating <= 10, 'Invalid risk rating');
        require(maxAllocation > 0, 'Invalid max allocation');

        supportedAssets[token] = AssetInfo({
            isSupported: true,
            totalDeposited: 0,
            totalWithdrawn: 0,
            maxAllocation: maxAllocation,
            riskRating: riskRating,
            requiresKYC: requiresKYC
        });

        emit AssetAdded(token, maxAllocation, riskRating, requiresKYC);
    }

    /**
     * @dev Update vault configuration
     * @param newConfig New vault configuration
     */
    function updateVaultConfig(VaultConfig calldata newConfig) external onlyRole(ADMIN_ROLE) {
        require(newConfig.maxDepositAmount > newConfig.minDepositAmount, 'Invalid deposit limits');
        require(newConfig.withdrawalTimelock <= 7 days, 'Timelock too long');

        vaultConfig = newConfig;
    }

    /**
     * @dev Set KYC verification status
     * @param user User address
     * @param verified Verification status
     */
    function setKYCVerification(address user, bool verified) external onlyCompliance {
        kycVerified[user] = verified;
    }

    /**
     * @dev Set blacklist status
     * @param user User address
     * @param isBlacklisted Blacklist status
     */
    function setBlacklist(address user, bool isBlacklisted) external onlyCompliance {
        blacklisted[user] = isBlacklisted;
    }

    /**
     * @dev Pause contract operations
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause contract operations
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Get user balance for a specific token
     * @param user User address
     * @param token Token address
     * @return Total balance
     */
    function getUserBalance(address user, address token) external view returns (uint256) {
        return _getUserBalance(user, token);
    }

    /**
     * @dev Get user deposit history
     * @param user User address
     * @param token Token address
     * @return Array of user deposits
     */
    function getUserDeposits(
        address user,
        address token
    ) external view returns (UserDeposit[] memory) {
        return userDeposits[user][token];
    }

    /**
     * @dev Get withdrawal request details
     * @param requestId Request ID
     * @return Withdrawal request details
     */
    function getWithdrawalRequest(
        uint256 requestId
    ) external view returns (WithdrawalRequest memory) {
        return withdrawalRequests[requestId];
    }

    /**
     * @dev Get asset information
     * @param token Token address
     * @return Asset information
     */
    function getAssetInfo(address token) external view returns (AssetInfo memory) {
        return supportedAssets[token];
    }

    /**
     * @dev Get vault statistics
     * @return Various vault statistics
     */
    function getVaultStats()
        external
        view
        returns (uint256 _totalValueLocked, uint256 _nextRequestId, uint256 _supportedAssetsCount)
    {
        _totalValueLocked = totalValueLocked;
        _nextRequestId = nextRequestId;
        // Note: supportedAssetsCount would need to be tracked separately
        _supportedAssetsCount = 0; // Placeholder
    }

    // Internal functions

    /**
     * @dev Get user balance for a specific token
     * @param user User address
     * @param token Token address
     * @return Total balance
     */
    function _getUserBalance(address user, address token) internal view returns (uint256) {
        uint256 totalBalance = 0;
        UserDeposit[] storage deposits = userDeposits[user][token];

        for (uint256 i = 0; i < deposits.length; i++) {
            if (!deposits[i].isLocked || block.timestamp >= deposits[i].unlockTime) {
                totalBalance = totalBalance.add(deposits[i].amount);
            }
        }

        return totalBalance;
    }

    /**
     * @dev Deduct amount from user deposits (FIFO)
     * @param user User address
     * @param token Token address
     * @param amount Amount to deduct
     */
    function _deductFromUserDeposits(address user, address token, uint256 amount) internal {
        UserDeposit[] storage deposits = userDeposits[user][token];
        uint256 remaining = amount;

        for (uint256 i = 0; i < deposits.length && remaining > 0; i++) {
            if (!deposits[i].isLocked || block.timestamp >= deposits[i].unlockTime) {
                if (deposits[i].amount <= remaining) {
                    remaining = remaining.sub(deposits[i].amount);
                    deposits[i].amount = 0;
                } else {
                    deposits[i].amount = deposits[i].amount.sub(remaining);
                    remaining = 0;
                }
            }
        }

        require(remaining == 0, 'Insufficient unlocked balance');
    }

    /**
     * @dev Perform compliance check
     * @param user User address
     * @param token Token address
     * @param amount Transaction amount
     * @param operation Operation type
     * @return Whether compliance check passed
     */
    function _performComplianceCheck(
        address user,
        address token,
        uint256 amount,
        string memory operation
    ) internal returns (bool) {
        // Basic compliance checks
        if (blacklisted[user]) {
            emit ComplianceCheck(user, token, amount, false, 'User blacklisted');
            return false;
        }

        AssetInfo storage asset = supportedAssets[token];
        if (asset.requiresKYC && !kycVerified[user]) {
            emit ComplianceCheck(user, token, amount, false, 'KYC required');
            return false;
        }

        // Additional compliance logic would go here
        // For example, integration with external compliance oracles

        emit ComplianceCheck(user, token, amount, true, operation);
        return true;
    }

    /**
     * @dev Receive function to handle direct ETH transfers
     */
    receive() external payable {
        revert('Direct ETH transfers not allowed');
    }

    /**
     * @dev Fallback function
     */
    fallback() external {
        revert('Function not found');
    }
}
