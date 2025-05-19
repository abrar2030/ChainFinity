// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "@chainlink/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

/**
 * @title Enhanced CrossChainManager
 * @dev Manages cross-chain transfers with Chainlink CCIP integration, rate limiting, and circuit breakers
 */
contract CrossChainManager is ReentrancyGuard, AccessControl, Pausable, Initializable, IAny2EVMMessageReceiver {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    // Chainlink CCIP Router
    IRouterClient public router;
    
    // Rate limiting
    uint256 public transferLimit;
    uint256 public transferCooldown;
    mapping(address => uint256) public lastTransferTime;
    
    // Circuit breaker
    uint256 public dailyTransferLimit;
    uint256 public dailyTransferTotal;
    uint256 public dailyResetTimestamp;
    
    // Fee sharing
    uint256 public liquidityProviderFee; // in basis points (1/100 of a percent)
    mapping(address => uint256) public liquidityProviderShares;
    uint256 public totalLiquidityShares;
    
    struct CrossChainTransfer {
        address sender;
        address token;
        uint256 amount;
        uint256 targetChainId;
        address targetAddress;
        uint256 timestamp;
        bool completed;
        bytes32 ccipMessageId;
    }
    
    mapping(bytes32 => CrossChainTransfer) public transfers;
    mapping(uint64 => bool) public supportedChains; // Using uint64 for Chainlink CCIP compatibility
    uint256 public transferCount;
    
    // Events
    event TransferInitiated(
        bytes32 indexed transferId,
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint64 targetChainId,
        address targetAddress,
        bytes32 ccipMessageId
    );
    event TransferCompleted(bytes32 indexed transferId);
    event ChainSupported(uint64 chainId, bool supported);
    event RateLimitUpdated(uint256 transferLimit, uint256 transferCooldown);
    event CircuitBreakerUpdated(uint256 dailyTransferLimit);
    event LiquidityProviderAdded(address indexed provider, uint256 shares);
    event LiquidityProviderRemoved(address indexed provider);
    event FeesDistributed(uint256 totalFees);
    event MessageReceived(bytes32 indexed messageId, uint64 sourceChainId);
    
    /**
     * @dev Initialize function for upgradeable pattern
     */
    function initialize(
        address admin,
        address operator,
        address emergency,
        address routerAddress
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);
        _grantRole(EMERGENCY_ROLE, emergency);
        
        router = IRouterClient(routerAddress);
        
        // Initialize supported chains (using Chainlink CCIP chain selectors)
        supportedChains[5009297550715157269] = true;  // Ethereum Mainnet
        supportedChains[4949039107694359620] = true;  // Arbitrum
        supportedChains[4051577828743386545] = true;  // Polygon
        
        // Set default rate limits
        transferLimit = 100000 * 10**18;      // 100,000 tokens
        transferCooldown = 1 hours;           // 1 hour cooldown
        dailyTransferLimit = 1000000 * 10**18; // 1,000,000 tokens daily limit
        dailyResetTimestamp = block.timestamp + 1 days;
        
        // Set default fee sharing
        liquidityProviderFee = 20; // 0.2%
    }
    
    /**
     * @dev Initiate a cross-chain transfer using Chainlink CCIP
     * @param token Token address
     * @param amount Amount to transfer
     * @param targetChainId Target chain ID (Chainlink selector)
     * @param targetAddress Target address on destination chain
     */
    function initiateTransfer(
        address token,
        uint256 amount,
        uint64 targetChainId,
        address targetAddress
    ) external nonReentrant whenNotPaused {
        // Check rate limits
        require(supportedChains[targetChainId], "Unsupported target chain");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= transferLimit, "Amount exceeds transfer limit");
        require(block.timestamp >= lastTransferTime[msg.sender] + transferCooldown, "Transfer cooldown active");
        
        // Check circuit breaker
        if (block.timestamp > dailyResetTimestamp) {
            dailyTransferTotal = 0;
            dailyResetTimestamp = block.timestamp + 1 days;
        }
        require(dailyTransferTotal + amount <= dailyTransferLimit, "Daily transfer limit reached");
        
        // Update rate limiting state
        lastTransferTime[msg.sender] = block.timestamp;
        dailyTransferTotal += amount;
        
        // Calculate fees
        uint256 lpFee = (amount * liquidityProviderFee) / 10000;
        uint256 netAmount = amount - lpFee;
        
        // Transfer tokens to this contract
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        // Prepare CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(targetAddress),
            data: abi.encode(msg.sender, token, netAmount),
            tokenAmounts: new Client.EVMTokenAmount[](0), // No tokens sent through CCIP directly
            extraArgs: "",
            feeToken: address(0) // Use native gas token for fees
        });
        
        // Get the fee required for sending the message
        uint256 ccipFee = router.getFee(targetChainId, message);
        
        // Send the CCIP message
        bytes32 messageId = router.ccipSend{value: ccipFee}(targetChainId, message);
        
        // Create transfer record
        bytes32 transferId = keccak256(
            abi.encodePacked(
                msg.sender,
                token,
                amount,
                targetChainId,
                targetAddress,
                block.timestamp,
                transferCount
            )
        );
        
        transfers[transferId] = CrossChainTransfer({
            sender: msg.sender,
            token: token,
            amount: netAmount,
            targetChainId: targetChainId,
            targetAddress: targetAddress,
            timestamp: block.timestamp,
            completed: false,
            ccipMessageId: messageId
        });
        
        transferCount++;
        
        emit TransferInitiated(
            transferId, 
            msg.sender, 
            token, 
            netAmount, 
            targetChainId, 
            targetAddress,
            messageId
        );
    }
    
    /**
     * @dev Receive and process messages from Chainlink CCIP
     * @param message The CCIP message
     */
    function ccipReceive(Client.Any2EVMMessage calldata message) external override {
        // Verify the sender is the router
        require(msg.sender == address(router), "Sender not router");
        
        // Decode the message data
        (address sender, address token, uint256 amount) = abi.decode(
            message.data,
            (address, address, uint256)
        );
        
        // Process the received message
        address receiver = abi.decode(message.receiver, (address));
        
        // Transfer tokens to the receiver
        require(IERC20(token).transfer(receiver, amount), "Token transfer failed");
        
        emit MessageReceived(message.messageId, message.sourceChainSelector);
    }
    
    /**
     * @dev Add or update a supported chain
     * @param chainId Chainlink CCIP chain selector
     * @param supported Whether the chain is supported
     */
    function setSupportedChain(uint64 chainId, bool supported) external onlyRole(ADMIN_ROLE) {
        supportedChains[chainId] = supported;
        emit ChainSupported(chainId, supported);
    }
    
    /**
     * @dev Update rate limits
     * @param newTransferLimit New transfer limit
     * @param newTransferCooldown New transfer cooldown
     */
    function updateRateLimit(uint256 newTransferLimit, uint256 newTransferCooldown) external onlyRole(ADMIN_ROLE) {
        transferLimit = newTransferLimit;
        transferCooldown = newTransferCooldown;
        emit RateLimitUpdated(newTransferLimit, newTransferCooldown);
    }
    
    /**
     * @dev Update circuit breaker
     * @param newDailyTransferLimit New daily transfer limit
     */
    function updateCircuitBreaker(uint256 newDailyTransferLimit) external onlyRole(ADMIN_ROLE) {
        dailyTransferLimit = newDailyTransferLimit;
        emit CircuitBreakerUpdated(newDailyTransferLimit);
    }
    
    /**
     * @dev Add a liquidity provider
     * @param provider Provider address
     * @param shares Number of shares
     */
    function addLiquidityProvider(address provider, uint256 shares) external onlyRole(ADMIN_ROLE) {
        require(provider != address(0), "Invalid provider address");
        require(shares > 0, "Shares must be greater than 0");
        
        liquidityProviderShares[provider] += shares;
        totalLiquidityShares += shares;
        
        emit LiquidityProviderAdded(provider, shares);
    }
    
    /**
     * @dev Remove a liquidity provider
     * @param provider Provider address
     */
    function removeLiquidityProvider(address provider) external onlyRole(ADMIN_ROLE) {
        require(liquidityProviderShares[provider] > 0, "Provider does not exist");
        
        totalLiquidityShares -= liquidityProviderShares[provider];
        liquidityProviderShares[provider] = 0;
        
        emit LiquidityProviderRemoved(provider);
    }
    
    /**
     * @dev Distribute collected fees to liquidity providers
     * @param token Token address
     */
    function distributeFees(address token) external onlyRole(OPERATOR_ROLE) {
        require(totalLiquidityShares > 0, "No liquidity providers");
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No fees to distribute");
        
        uint256 totalDistributed = 0;
        
        // Distribute to each provider based on their share
        for (uint256 i = 0; i < getRoleMembers(OPERATOR_ROLE).length; i++) {
            address provider = getRoleMembers(OPERATOR_ROLE)[i];
            if (liquidityProviderShares[provider] > 0) {
                uint256 providerShare = (balance * liquidityProviderShares[provider]) / totalLiquidityShares;
                if (providerShare > 0) {
                    require(IERC20(token).transfer(provider, providerShare), "Fee transfer failed");
                    totalDistributed += providerShare;
                }
            }
        }
        
        emit FeesDistributed(totalDistributed);
    }
    
    /**
     * @dev Get all members with a specific role
     * @param role Role to query
     * @return Array of addresses with the role
     */
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < 100; i++) { // Arbitrary upper limit
            try this.getRoleMember(role, i) returns (address member) {
                if (member == address(0)) break;
                count++;
            } catch {
                break;
            }
        }
        
        address[] memory members = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            members[i] = getRoleMember(role, i);
        }
        
        return members;
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
     * @dev Get transfer details
     * @param transferId Transfer ID
     */
    function getTransfer(bytes32 transferId) external view returns (CrossChainTransfer memory) {
        return transfers[transferId];
    }
    
    /**
     * @dev Receive function to accept ETH for CCIP fees
     */
    receive() external payable {}
}
