// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

/**
 * @title ChainFinityGovernor
 * @dev Governance contract for ChainFinity platform with timelock, voting, and quorum capabilities
 */
contract ChainFinityGovernor is 
    Governor, 
    GovernorSettings, 
    GovernorCountingSimple, 
    GovernorVotes, 
    GovernorVotesQuorumFraction, 
    GovernorTimelockControl 
{
    /**
     * @dev Constructor that initializes the governor with required parameters
     * @param _token The governance token used for voting
     * @param _timelock The timelock controller used for governance proposals
     */
    constructor(
        IVotes _token,
        TimelockController _timelock
    )
        Governor("ChainFinity Governor")
        GovernorSettings(
            1 days, /* Voting delay: 1 day */
            7 days, /* Voting period: 1 week */
            0 /* Proposal threshold: 0 tokens */
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4) /* 4% quorum */
        GovernorTimelockControl(_timelock)
    {}

    /**
     * @dev Function to support quadratic voting (optional enhancement)
     * @param proposalId The ID of the proposal
     * @param account The account that cast the vote
     * @param support The type of support (0=against, 1=for, 2=abstain)
     * @param weight The weight of the vote
     * @param params Additional parameters for quadratic voting
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal override(GovernorCountingSimple) {
        // If quadratic voting is enabled and params are provided
        if (params.length > 0) {
            // Extract quadratic voting flag from params
            bool useQuadratic = abi.decode(params, (bool));
            
            if (useQuadratic) {
                // Apply quadratic voting formula: sqrt(weight)
                uint256 quadraticWeight = sqrt(weight);
                super._countVote(proposalId, account, support, quadraticWeight, "");
                return;
            }
        }
        
        // Default to standard voting if quadratic not specified
        super._countVote(proposalId, account, support, weight, "");
    }

    /**
     * @dev Helper function to calculate square root for quadratic voting
     * @param x The number to calculate the square root of
     * @return y The square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // The following functions are overrides required by Solidity

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
