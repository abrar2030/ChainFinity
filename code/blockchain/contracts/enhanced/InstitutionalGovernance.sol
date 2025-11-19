// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title InstitutionalGovernance
 * @dev Advanced governance contract for institutional-grade decision making
 * @notice Supports multiple voting mechanisms, delegation, and compliance features
 */
contract InstitutionalGovernance is ReentrancyGuard, Pausable, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Voting mechanisms
    enum VotingMechanism {
        SimpleVoting,      // One token = one vote
        QuadraticVoting,   // Square root of tokens
        WeightedVoting,    // Custom weights
        DelegatedVoting,   // Delegation support
        MultiSigVoting     // Multi-signature style
    }

    // Proposal types
    enum ProposalType {
        Parameter,         // Parameter changes
        Treasury,          // Treasury operations
        Upgrade,           // Contract upgrades
        Emergency,         // Emergency actions
        Strategic,         // Strategic decisions
        Compliance        // Compliance changes
    }

    // Proposal status
    enum ProposalStatus {
        Pending,          // Waiting for voting period
        Active,           // Currently voting
        Succeeded,        // Passed voting
        Defeated,         // Failed voting
        Queued,           // Queued for execution
        Executed,         // Successfully executed
        Cancelled,        // Cancelled
        Expired           // Expired without execution
    }

    // Vote choice
    enum VoteChoice {
        Against,
        For,
        Abstain
    }

    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        VotingMechanism votingMechanism;
        string title;
        string description;
        bytes32 descriptionHash;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 startTime;
        uint256 endTime;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 totalVotingPower;
        uint256 quorumRequired;
        uint256 approvalThreshold;
        ProposalStatus status;
        bool requiresCompliance;
        mapping(address => Vote) votes;
        mapping(address => uint256) delegatedVotes;
    }

    // Vote structure
    struct Vote {
        bool hasVoted;
        VoteChoice choice;
        uint256 weight;
        uint256 timestamp;
        string reason;
    }

    // Delegation structure
    struct Delegation {
        address delegate;
        uint256 amount;
        uint256 timestamp;
        bool isActive;
    }

    // Governance parameters
    struct GovernanceParams {
        uint256 votingDelay;           // Delay before voting starts
        uint256 votingPeriod;          // Duration of voting
        uint256 executionDelay;        // Delay before execution
        uint256 proposalThreshold;     // Minimum tokens to propose
        uint256 quorumNumerator;       // Quorum percentage (numerator)
        uint256 quorumDenominator;     // Quorum percentage (denominator)
        uint256 approvalThreshold;     // Approval threshold percentage
        uint256 maxProposalActions;    // Maximum actions per proposal
    }

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        ProposalType proposalType,
        string title,
        uint256 startTime,
        uint256 endTime
    );

    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        VoteChoice choice,
        uint256 weight,
        string reason
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor
    );

    event ProposalCancelled(
        uint256 indexed proposalId,
        address indexed canceller
    );

    event DelegationCreated(
        address indexed delegator,
        address indexed delegate,
        uint256 amount
    );

    event DelegationRevoked(
        address indexed delegator,
        address indexed delegate
    );

    event GovernanceParamsUpdated(
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 quorumNumerator
    );

    event ComplianceCheckRequired(
        uint256 indexed proposalId,
        address indexed checker
    );

    // State variables
    IERC20 public governanceToken;
    Counters.Counter private _proposalIds;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(address => Delegation)) public delegations;
    mapping(address => uint256) public votingPower;
    mapping(address => bool) public authorizedProposers;
    mapping(ProposalType => GovernanceParams) public typeParams;

    GovernanceParams public defaultParams;
    address public treasury;
    address public complianceOracle;
    uint256 public constant MAX_VOTING_PERIOD = 30 days;
    uint256 public constant MIN_VOTING_PERIOD = 1 hours;

    // Modifiers
    modifier onlyAuthorizedProposer() {
        require(
            hasRole(PROPOSER_ROLE, msg.sender) || authorizedProposers[msg.sender],
            "Not authorized to propose"
        );
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= _proposalIds.current(), "Invalid proposal ID");
        _;
    }

    modifier onlyActiveProposal(uint256 proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp >= proposals[proposalId].startTime, "Voting not started");
        require(block.timestamp <= proposals[proposalId].endTime, "Voting ended");
        _;
    }

    /**
     * @dev Constructor
     * @param _governanceToken Governance token address
     * @param _treasury Treasury address
     * @param _admin Admin address
     */
    constructor(
        address _governanceToken,
        address _treasury,
        address _admin
    ) {
        require(_governanceToken != address(0), "Invalid governance token");
        require(_treasury != address(0), "Invalid treasury");
        require(_admin != address(0), "Invalid admin");

        governanceToken = IERC20(_governanceToken);
        treasury = _treasury;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(PROPOSER_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _admin);
        _grantRole(GUARDIAN_ROLE, _admin);
        _grantRole(COMPLIANCE_ROLE, _admin);

        // Set default governance parameters
        defaultParams = GovernanceParams({
            votingDelay: 1 days,
            votingPeriod: 7 days,
            executionDelay: 2 days,
            proposalThreshold: 100000 * 10**18, // 100K tokens
            quorumNumerator: 4,                  // 4%
            quorumDenominator: 100,
            approvalThreshold: 51,               // 51%
            maxProposalActions: 10
        });
    }

    /**
     * @dev Create a new proposal
     * @param proposalType Type of proposal
     * @param votingMechanism Voting mechanism to use
     * @param title Proposal title
     * @param description Proposal description
     * @param targets Target contract addresses
     * @param values ETH values for each call
     * @param calldatas Encoded function calls
     * @param requiresCompliance Whether compliance check is required
     */
    function propose(
        ProposalType proposalType,
        VotingMechanism votingMechanism,
        string memory title,
        string memory description,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bool requiresCompliance
    )
        external
        onlyAuthorizedProposer
        whenNotPaused
        returns (uint256)
    {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(targets.length == values.length, "Targets and values length mismatch");
        require(targets.length == calldatas.length, "Targets and calldatas length mismatch");

        GovernanceParams memory params = _getProposalParams(proposalType);
        require(targets.length <= params.maxProposalActions, "Too many actions");

        // Check proposer has enough tokens
        uint256 proposerBalance = governanceToken.balanceOf(msg.sender);
        require(proposerBalance >= params.proposalThreshold, "Insufficient tokens to propose");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        uint256 startTime = block.timestamp.add(params.votingDelay);
        uint256 endTime = startTime.add(params.votingPeriod);

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = proposalType;
        proposal.votingMechanism = votingMechanism;
        proposal.title = title;
        proposal.description = description;
        proposal.descriptionHash = keccak256(bytes(description));
        proposal.targets = targets;
        proposal.values = values;
        proposal.calldatas = calldatas;
        proposal.startTime = startTime;
        proposal.endTime = endTime;
        proposal.status = ProposalStatus.Pending;
        proposal.requiresCompliance = requiresCompliance;
        proposal.quorumRequired = _calculateQuorum(proposalType);
        proposal.approvalThreshold = params.approvalThreshold;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            proposalType,
            title,
            startTime,
            endTime
        );

        return proposalId;
    }

    /**
     * @dev Cast a vote on a proposal
     * @param proposalId Proposal ID
     * @param choice Vote choice
     * @param reason Reason for vote (optional)
     */
    function castVote(
        uint256 proposalId,
        VoteChoice choice,
        string memory reason
    )
        external
        validProposal(proposalId)
        onlyActiveProposal(proposalId)
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.votes[msg.sender].hasVoted, "Already voted");

        uint256 weight = _getVotingWeight(msg.sender, proposal.votingMechanism);
        require(weight > 0, "No voting power");

        // Record vote
        proposal.votes[msg.sender] = Vote({
            hasVoted: true,
            choice: choice,
            weight: weight,
            timestamp: block.timestamp,
            reason: reason
        });

        // Update vote tallies
        if (choice == VoteChoice.For) {
            proposal.forVotes = proposal.forVotes.add(weight);
        } else if (choice == VoteChoice.Against) {
            proposal.againstVotes = proposal.againstVotes.add(weight);
        } else {
            proposal.abstainVotes = proposal.abstainVotes.add(weight);
        }

        proposal.totalVotingPower = proposal.totalVotingPower.add(weight);

        emit VoteCast(msg.sender, proposalId, choice, weight, reason);

        // Check if proposal should transition to succeeded/defeated
        _updateProposalStatus(proposalId);
    }

    /**
     * @dev Cast vote with signature (for meta-transactions)
     * @param proposalId Proposal ID
     * @param choice Vote choice
     * @param reason Reason for vote
     * @param voter Voter address
     * @param signature Voter's signature
     */
    function castVoteWithSignature(
        uint256 proposalId,
        VoteChoice choice,
        string memory reason,
        address voter,
        bytes memory signature
    )
        external
        validProposal(proposalId)
        onlyActiveProposal(proposalId)
        whenNotPaused
    {
        // Verify signature
        bytes32 hash = keccak256(abi.encodePacked(proposalId, uint8(choice), reason, voter));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(signature);
        require(signer == voter, "Invalid signature");

        Proposal storage proposal = proposals[proposalId];
        require(!proposal.votes[voter].hasVoted, "Already voted");

        uint256 weight = _getVotingWeight(voter, proposal.votingMechanism);
        require(weight > 0, "No voting power");

        // Record vote
        proposal.votes[voter] = Vote({
            hasVoted: true,
            choice: choice,
            weight: weight,
            timestamp: block.timestamp,
            reason: reason
        });

        // Update vote tallies
        if (choice == VoteChoice.For) {
            proposal.forVotes = proposal.forVotes.add(weight);
        } else if (choice == VoteChoice.Against) {
            proposal.againstVotes = proposal.againstVotes.add(weight);
        } else {
            proposal.abstainVotes = proposal.abstainVotes.add(weight);
        }

        proposal.totalVotingPower = proposal.totalVotingPower.add(weight);

        emit VoteCast(voter, proposalId, choice, weight, reason);

        // Check if proposal should transition to succeeded/defeated
        _updateProposalStatus(proposalId);
    }

    /**
     * @dev Delegate voting power to another address
     * @param delegate Address to delegate to
     * @param amount Amount of tokens to delegate
     */
    function delegate(address delegate, uint256 amount)
        external
        whenNotPaused
    {
        require(delegate != address(0), "Invalid delegate");
        require(delegate != msg.sender, "Cannot delegate to self");
        require(amount > 0, "Amount must be greater than 0");
        require(governanceToken.balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Revoke existing delegation if any
        if (delegations[msg.sender][delegate].isActive) {
            _revokeDelegation(msg.sender, delegate);
        }

        // Create new delegation
        delegations[msg.sender][delegate] = Delegation({
            delegate: delegate,
            amount: amount,
            timestamp: block.timestamp,
            isActive: true
        });

        // Update voting power
        votingPower[delegate] = votingPower[delegate].add(amount);

        emit DelegationCreated(msg.sender, delegate, amount);
    }

    /**
     * @dev Revoke delegation
     * @param delegate Address to revoke delegation from
     */
    function revokeDelegation(address delegate)
        external
        whenNotPaused
    {
        require(delegations[msg.sender][delegate].isActive, "No active delegation");
        _revokeDelegation(msg.sender, delegate);
    }

    /**
     * @dev Execute a successful proposal
     * @param proposalId Proposal ID
     */
    function execute(uint256 proposalId)
        external
        payable
        nonReentrant
        validProposal(proposalId)
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "Proposal not succeeded");
        require(block.timestamp > proposal.endTime, "Voting still active");

        GovernanceParams memory params = _getProposalParams(proposal.proposalType);
        uint256 executionTime = proposal.endTime.add(params.executionDelay);
        require(block.timestamp >= executionTime, "Execution delay not met");

        // Compliance check if required
        if (proposal.requiresCompliance) {
            require(_performComplianceCheck(proposalId), "Compliance check failed");
        }

        proposal.status = ProposalStatus.Executed;
        proposal.executionTime = block.timestamp;

        // Execute all actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                proposal.calldatas[i]
            );
            require(success, "Execution failed");
        }

        emit ProposalExecuted(proposalId, msg.sender);
    }

    /**
     * @dev Cancel a proposal (admin or proposer only)
     * @param proposalId Proposal ID
     */
    function cancel(uint256 proposalId)
        external
        validProposal(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to cancel"
        );
        require(
            proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active,
            "Cannot cancel proposal"
        );

        proposal.status = ProposalStatus.Cancelled;

        emit ProposalCancelled(proposalId, msg.sender);
    }

    /**
     * @dev Update governance parameters for a proposal type
     * @param proposalType Proposal type
     * @param params New parameters
     */
    function updateGovernanceParams(
        ProposalType proposalType,
        GovernanceParams memory params
    )
        external
        onlyRole(ADMIN_ROLE)
    {
        require(params.votingPeriod >= MIN_VOTING_PERIOD, "Voting period too short");
        require(params.votingPeriod <= MAX_VOTING_PERIOD, "Voting period too long");
        require(params.quorumNumerator <= params.quorumDenominator, "Invalid quorum");
        require(params.approvalThreshold <= 100, "Invalid approval threshold");

        typeParams[proposalType] = params;

        emit GovernanceParamsUpdated(
            params.votingDelay,
            params.votingPeriod,
            params.quorumNumerator
        );
    }

    /**
     * @dev Set authorized proposer status
     * @param proposer Proposer address
     * @param authorized Authorization status
     */
    function setAuthorizedProposer(address proposer, bool authorized)
        external
        onlyRole(ADMIN_ROLE)
    {
        authorizedProposers[proposer] = authorized;
    }

    /**
     * @dev Emergency pause
     */
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // View functions

    /**
     * @dev Get proposal details
     * @param proposalId Proposal ID
     * @return Proposal details
     */
    function getProposal(uint256 proposalId)
        external
        view
        validProposal(proposalId)
        returns (
            uint256 id,
            address proposer,
            ProposalType proposalType,
            string memory title,
            uint256 startTime,
            uint256 endTime,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            ProposalStatus status
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.proposalType,
            proposal.title,
            proposal.startTime,
            proposal.endTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.status
        );
    }

    /**
     * @dev Get vote details for a user on a proposal
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return Vote details
     */
    function getVote(uint256 proposalId, address voter)
        external
        view
        validProposal(proposalId)
        returns (
            bool hasVoted,
            VoteChoice choice,
            uint256 weight,
            uint256 timestamp,
            string memory reason
        )
    {
        Vote storage vote = proposals[proposalId].votes[voter];
        return (
            vote.hasVoted,
            vote.choice,
            vote.weight,
            vote.timestamp,
            vote.reason
        );
    }

    /**
     * @dev Get current proposal count
     * @return Current proposal count
     */
    function proposalCount() external view returns (uint256) {
        return _proposalIds.current();
    }

    /**
     * @dev Get voting power for an address
     * @param account Account address
     * @param mechanism Voting mechanism
     * @return Voting power
     */
    function getVotingPower(address account, VotingMechanism mechanism)
        external
        view
        returns (uint256)
    {
        return _getVotingWeight(account, mechanism);
    }

    // Internal functions

    /**
     * @dev Get voting weight based on mechanism
     * @param account Account address
     * @param mechanism Voting mechanism
     * @return Voting weight
     */
    function _getVotingWeight(address account, VotingMechanism mechanism)
        internal
        view
        returns (uint256)
    {
        uint256 balance = governanceToken.balanceOf(account);
        uint256 delegated = votingPower[account];
        uint256 totalPower = balance.add(delegated);

        if (mechanism == VotingMechanism.SimpleVoting) {
            return totalPower;
        } else if (mechanism == VotingMechanism.QuadraticVoting) {
            return _sqrt(totalPower);
        } else if (mechanism == VotingMechanism.WeightedVoting) {
            // Custom weight calculation would go here
            return totalPower;
        } else if (mechanism == VotingMechanism.DelegatedVoting) {
            return totalPower;
        } else if (mechanism == VotingMechanism.MultiSigVoting) {
            return totalPower > 0 ? 1 : 0; // One vote per address
        }

        return totalPower;
    }

    /**
     * @dev Calculate square root (for quadratic voting)
     * @param x Input value
     * @return Square root
     */
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = x.add(1).div(2);
        uint256 y = x;
        while (z < y) {
            y = z;
            z = x.div(z).add(z).div(2);
        }
        return y;
    }

    /**
     * @dev Get proposal parameters for a type
     * @param proposalType Proposal type
     * @return Governance parameters
     */
    function _getProposalParams(ProposalType proposalType)
        internal
        view
        returns (GovernanceParams memory)
    {
        GovernanceParams memory params = typeParams[proposalType];

        // Use default if not set
        if (params.votingPeriod == 0) {
            return defaultParams;
        }

        return params;
    }

    /**
     * @dev Calculate quorum for proposal type
     * @param proposalType Proposal type
     * @return Required quorum
     */
    function _calculateQuorum(ProposalType proposalType)
        internal
        view
        returns (uint256)
    {
        GovernanceParams memory params = _getProposalParams(proposalType);
        uint256 totalSupply = governanceToken.totalSupply();

        return totalSupply.mul(params.quorumNumerator).div(params.quorumDenominator);
    }

    /**
     * @dev Update proposal status based on votes
     * @param proposalId Proposal ID
     */
    function _updateProposalStatus(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.status != ProposalStatus.Active) {
            return;
        }

        // Check if voting period ended
        if (block.timestamp > proposal.endTime) {
            uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);

            // Check quorum
            if (totalVotes >= proposal.quorumRequired) {
                // Check approval threshold
                uint256 approvalRate = proposal.forVotes.mul(100).div(totalVotes);

                if (approvalRate >= proposal.approvalThreshold) {
                    proposal.status = ProposalStatus.Succeeded;
                } else {
                    proposal.status = ProposalStatus.Defeated;
                }
            } else {
                proposal.status = ProposalStatus.Defeated;
            }
        }
    }

    /**
     * @dev Revoke delegation internal function
     * @param delegator Delegator address
     * @param delegate Delegate address
     */
    function _revokeDelegation(address delegator, address delegate) internal {
        Delegation storage delegation = delegations[delegator][delegate];
        require(delegation.isActive, "No active delegation");

        uint256 amount = delegation.amount;
        delegation.isActive = false;

        // Update voting power
        votingPower[delegate] = votingPower[delegate].sub(amount);

        emit DelegationRevoked(delegator, delegate);
    }

    /**
     * @dev Perform compliance check
     * @param proposalId Proposal ID
     * @return Whether compliance check passed
     */
    function _performComplianceCheck(uint256 proposalId)
        internal
        returns (bool)
    {
        // This would integrate with external compliance systems
        // For now, return true if compliance role approves

        emit ComplianceCheckRequired(proposalId, msg.sender);

        // Basic compliance check - can be extended
        return hasRole(COMPLIANCE_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Receive function
     */
    receive() external payable {
        // Allow contract to receive ETH for proposal execution
    }
}
