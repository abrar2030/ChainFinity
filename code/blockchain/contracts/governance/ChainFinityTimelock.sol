// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/governance/TimelockController.sol';

/**
 * @title ChainFinityTimelock
 * @dev Timelock controller for ChainFinity governance
 * Adds a time delay to governance actions for security
 */
contract ChainFinityTimelock is TimelockController {
    /**
     * @dev Constructor that initializes the timelock with required parameters
     * @param minDelay The minimum delay before execution
     * @param proposers The addresses that can propose
     * @param executors The addresses that can execute
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    )
        TimelockController(
            minDelay,
            proposers,
            executors,
            msg.sender // admin
        )
    {}
}
