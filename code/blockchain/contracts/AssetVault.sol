// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AssetVault is ReentrancyGuard, Ownable {
    struct Asset {
        address token;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Asset[]) public userAssets;
    mapping(address => mapping(address => uint256)) public userTokenBalances;

    event AssetDeposited(address indexed user, address indexed token, uint256 amount);
    event AssetWithdrawn(address indexed user, address indexed token, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function deposit(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        userAssets[msg.sender].push(Asset({
            token: token,
            amount: amount,
            timestamp: block.timestamp
        }));

        userTokenBalances[msg.sender][token] += amount;
        emit AssetDeposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(userTokenBalances[msg.sender][token] >= amount, "Insufficient balance");

        userTokenBalances[msg.sender][token] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");

        emit AssetWithdrawn(msg.sender, token, amount);
    }

    function getUserAssets(address user) external view returns (Asset[] memory) {
        return userAssets[user];
    }

    function getUserTokenBalance(address user, address token) external view returns (uint256) {
        return userTokenBalances[user][token];
    }
}
