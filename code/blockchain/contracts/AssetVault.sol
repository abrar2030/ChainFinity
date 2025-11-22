// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

/**
 * @title Enhanced AssetVault
 * @dev Secure vault for managing user assets with multi-sig, fees, and emergency controls
 */
contract AssetVault is ReentrancyGuard, AccessControl, Pausable, Initializable {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    bytes32 public constant EMERGENCY_ROLE = keccak256('EMERGENCY_ROLE');

    // Fee configuration
    uint256 public depositFeeRate; // Fee rate in basis points (1/100 of a percent)
    uint256 public withdrawFeeRate; // Fee rate in basis points
    address public feeCollector;
    uint256 public constant MAX_FEE_RATE = 500; // 5% maximum fee

    // Multi-sig threshold configuration
    uint256 public largeTransferThreshold;
    uint256 public requiredApprovals;

    struct Asset {
        address token;
        uint256 amount;
        uint256 timestamp;
    }

    struct WithdrawalRequest {
        address user;
        address token;
        uint256 amount;
        uint256 timestamp;
        uint256 approvals;
        bool executed;
        mapping(address => bool) hasApproved;
    }

    // Storage
    mapping(address => Asset[]) public userAssets;
    mapping(address => mapping(address => uint256)) public userTokenBalances;
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    uint256 public nextWithdrawalRequestId;

    // Frozen assets tracking
    mapping(address => bool) public frozenTokens;
    mapping(address => mapping(address => bool)) public frozenUserAssets;

    // Events
    event AssetDeposited(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event AssetWithdrawn(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event WithdrawalRequested(
        uint256 indexed requestId,
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event WithdrawalApproved(uint256 indexed requestId, address indexed approver);
    event WithdrawalExecuted(uint256 indexed requestId);
    event AssetFrozen(address indexed token, bool frozen);
    event UserAssetFrozen(address indexed user, address indexed token, bool frozen);
    event FeeUpdated(uint256 depositFeeRate, uint256 withdrawFeeRate);
    event FeeCollectorUpdated(address indexed newFeeCollector);
    event ThresholdUpdated(uint256 largeTransferThreshold, uint256 requiredApprovals);

    /**
     * @dev Initialize function for upgradeable pattern
     */
    function initialize(
        address admin,
        address operator,
        address emergency,
        address _feeCollector
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(EMERGENCY_ROLE, emergency);

        depositFeeRate = 10; // 0.1% default fee
        withdrawFeeRate = 20; // 0.2% default fee
        feeCollector = _feeCollector;

        largeTransferThreshold = 100000 * 10 ** 18; // 100,000 tokens default threshold
        requiredApprovals = 2; // Default required approvals
    }

    /**
     * @dev Deposit assets with optional permit for gasless approvals
     * @param token Token address to deposit
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) external nonReentrant whenNotPaused {
        _deposit(token, amount);
    }

    /**
     * @dev Deposit with EIP-2612 permit
     * @param token Token address to deposit
     * @param amount Amount to deposit
     * @param deadline Permit deadline
     * @param v Signature v
     * @param r Signature r
     * @param s Signature s
     */
    function depositWithPermit(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant whenNotPaused {
        IERC20Permit(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(token, amount);
    }

    /**
     * @dev Internal deposit implementation
     */
    function _deposit(address token, uint256 amount) internal {
        require(amount > 0, 'Amount must be greater than 0');
        require(!frozenTokens[token], 'Token is frozen');
        require(!frozenUserAssets[msg.sender][token], 'User assets are frozen');

        // Calculate and deduct fee
        uint256 fee = (amount * depositFeeRate) / 10000;
        uint256 netAmount = amount - fee;

        // Transfer tokens
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), 'Transfer failed');

        // Transfer fee to collector if applicable
        if (fee > 0 && feeCollector != address(0)) {
            require(IERC20(token).transfer(feeCollector, fee), 'Fee transfer failed');
        }

        // Update user balances
        userAssets[msg.sender].push(
            Asset({token: token, amount: netAmount, timestamp: block.timestamp})
        );

        userTokenBalances[msg.sender][token] += netAmount;
        emit AssetDeposited(msg.sender, token, netAmount, fee);
    }

    /**
     * @dev Withdraw assets directly if under threshold
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function withdraw(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, 'Amount must be greater than 0');
        require(!frozenTokens[token], 'Token is frozen');
        require(!frozenUserAssets[msg.sender][token], 'User assets are frozen');
        // Calculate net amount after fee
        uint256 fee = (amount * withdrawFeeRate) / 10000;
        uint256 netAmount = amount - fee;

        require(userTokenBalances[msg.sender][token] >= amount, 'Insufficient balance');

        // Check if multi-sig is required (using gross amount for threshold)
        if (amount >= largeTransferThreshold) {
            _requestWithdrawal(token, amount);
        } else {
            _executeWithdrawal(msg.sender, token, amount);
        }
    }

    /**
     * @dev Request a withdrawal for large amounts
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function _requestWithdrawal(address token, uint256 amount) internal {
        uint256 requestId = nextWithdrawalRequestId++;

        WithdrawalRequest storage request = withdrawalRequests[requestId];
        request.user = msg.sender;
        request.token = token;
        request.amount = amount;
        request.timestamp = block.timestamp;
        request.approvals = 0;
        request.executed = false;

        emit WithdrawalRequested(requestId, msg.sender, token, amount);
    }

    /**
     * @dev Approve a withdrawal request
     * @param requestId ID of the withdrawal request
     */
    function approveWithdrawal(uint256 requestId) external onlyRole(OPERATOR_ROLE) {
        WithdrawalRequest storage request = withdrawalRequests[requestId];

        require(!request.executed, 'Request already executed');
        require(request.user != address(0), 'Request does not exist');
        require(!request.hasApproved[msg.sender], 'Already approved');

        request.hasApproved[msg.sender] = true;
        request.approvals += 1;

        emit WithdrawalApproved(requestId, msg.sender);

        // Execute if threshold met
        if (request.approvals >= requiredApprovals) {
            _executeWithdrawal(request.user, request.token, request.amount);
            request.executed = true;
            emit WithdrawalExecuted(requestId);
        }
    }

    /**
     * @dev Execute a withdrawal
     * @param user User address
     * @param token Token address
     * @param amount Amount to withdraw
     */
    function _executeWithdrawal(address user, address token, uint256 amount) internal {
        // Calculate and deduct fee
        uint256 fee = (amount * withdrawFeeRate) / 10000;
        uint256 netAmount = amount - fee;

        // Update user balance
        userTokenBalances[user][token] -= netAmount;

        // Transfer tokens
        require(IERC20(token).transfer(user, netAmount), 'Transfer failed');

        // Transfer fee to collector if applicable
        if (fee > 0 && feeCollector != address(0)) {
            require(IERC20(token).transfer(feeCollector, fee), 'Fee transfer failed');
        }

        emit AssetWithdrawn(user, token, netAmount, fee);
    }

    /**
     * @dev Batch deposit for gas efficiency
     * @param tokens Array of token addresses
     * @param amounts Array of amounts
     */
    function batchDeposit(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        require(tokens.length == amounts.length, 'Arrays length mismatch');

        for (uint256 i = 0; i < tokens.length; i++) {
            _deposit(tokens[i], amounts[i]);
        }
    }

    /**
     * @dev Batch withdraw for gas efficiency
     * @param tokens Array of token addresses
     * @param amounts Array of amounts
     */
    function batchWithdraw(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        require(tokens.length == amounts.length, 'Arrays length mismatch');

        for (uint256 i = 0; i < tokens.length; i++) {
            require(amounts[i] > 0, 'Amount must be greater than 0');
            require(!frozenTokens[tokens[i]], 'Token is frozen');
            require(!frozenUserAssets[msg.sender][tokens[i]], 'User assets are frozen');
            require(userTokenBalances[msg.sender][tokens[i]] >= amounts[i], 'Insufficient balance');

            // Check if multi-sig is required
            if (amounts[i] >= largeTransferThreshold) {
                _requestWithdrawal(tokens[i], amounts[i]);
            } else {
                _executeWithdrawal(msg.sender, tokens[i], amounts[i]);
            }
        }
    }

    /**
     * @dev Freeze/unfreeze a token
     * @param token Token address
     * @param frozen Frozen state
     */
    function setTokenFrozen(address token, bool frozen) external onlyRole(EMERGENCY_ROLE) {
        frozenTokens[token] = frozen;
        emit AssetFrozen(token, frozen);
    }

    /**
     * @dev Freeze/unfreeze a user's assets
     * @param user User address
     * @param token Token address
     * @param frozen Frozen state
     */
    function setUserAssetFrozen(
        address user,
        address token,
        bool frozen
    ) external onlyRole(EMERGENCY_ROLE) {
        frozenUserAssets[user][token] = frozen;
        emit UserAssetFrozen(user, token, frozen);
    }

    /**
     * @dev Update fee rates
     * @param newDepositFeeRate New deposit fee rate
     * @param newWithdrawFeeRate New withdraw fee rate
     */
    function updateFeeRates(
        uint256 newDepositFeeRate,
        uint256 newWithdrawFeeRate
    ) external onlyRole(ADMIN_ROLE) {
        require(newDepositFeeRate <= MAX_FEE_RATE, 'Deposit fee too high');
        require(newWithdrawFeeRate <= MAX_FEE_RATE, 'Withdraw fee too high');

        depositFeeRate = newDepositFeeRate;
        withdrawFeeRate = newWithdrawFeeRate;

        emit FeeUpdated(newDepositFeeRate, newWithdrawFeeRate);
    }

    /**
     * @dev Update fee collector
     * @param newFeeCollector New fee collector address
     */
    function updateFeeCollector(address newFeeCollector) external onlyRole(ADMIN_ROLE) {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    /**
     * @dev Update large transfer threshold and required approvals
     * @param newThreshold New large transfer threshold
     * @param newRequiredApprovals New required approvals count
     */
    function updateThresholds(
        uint256 newThreshold,
        uint256 newRequiredApprovals
    ) external onlyRole(ADMIN_ROLE) {
        largeTransferThreshold = newThreshold;
        requiredApprovals = newRequiredApprovals;

        emit ThresholdUpdated(newThreshold, newRequiredApprovals);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Get user assets
     * @param user User address
     */
    function getUserAssets(address user) external view returns (Asset[] memory) {
        return userAssets[user];
    }

    /**
     * @dev Get user token balance
     * @param user User address
     * @param token Token address
     */
    function getUserTokenBalance(address user, address token) external view returns (uint256) {
        return userTokenBalances[user][token];
    }
}
