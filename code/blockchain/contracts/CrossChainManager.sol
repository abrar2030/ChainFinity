// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainManager is ReentrancyGuard, Ownable {
    struct CrossChainTransfer {
        address sender;
        address token;
        uint256 amount;
        uint256 targetChainId;
        address targetAddress;
        uint256 timestamp;
        bool completed;
    }

    mapping(bytes32 => CrossChainTransfer) public transfers;
    mapping(uint256 => bool) public supportedChains;
    uint256 public transferCount;

    event TransferInitiated(
        bytes32 indexed transferId,
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint256 targetChainId,
        address targetAddress
    );
    event TransferCompleted(bytes32 indexed transferId);

    constructor() Ownable(msg.sender) {
        // Initialize supported chains (example: Ethereum Mainnet, Arbitrum, Polygon)
        supportedChains[1] = true;    // Ethereum Mainnet
        supportedChains[42161] = true; // Arbitrum
        supportedChains[137] = true;   // Polygon
    }

    function initiateTransfer(
        address token,
        uint256 amount,
        uint256 targetChainId,
        address targetAddress
    ) external nonReentrant {
        require(supportedChains[targetChainId], "Unsupported target chain");
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

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
            amount: amount,
            targetChainId: targetChainId,
            targetAddress: targetAddress,
            timestamp: block.timestamp,
            completed: false
        });

        transferCount++;
        emit TransferInitiated(transferId, msg.sender, token, amount, targetChainId, targetAddress);
    }

    function completeTransfer(bytes32 transferId) external onlyOwner {
        CrossChainTransfer storage transfer = transfers[transferId];
        require(transfer.sender != address(0), "Transfer does not exist");
        require(!transfer.completed, "Transfer already completed");

        transfer.completed = true;
        emit TransferCompleted(transferId);
    }

    function addSupportedChain(uint256 chainId) external onlyOwner {
        supportedChains[chainId] = true;
    }

    function removeSupportedChain(uint256 chainId) external onlyOwner {
        supportedChains[chainId] = false;
    }

    function getTransfer(bytes32 transferId) external view returns (CrossChainTransfer memory) {
        return transfers[transferId];
    }
}
