// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
* @title Voting - A voting mechanism to vote before the proposal is listed on the list for donations
* @notice This contract implements a voting mechanism before the proposal is ready to be donated
**/

import "./proposal.sol";
//import "./lagoonToken.sol";

contract Voting {
    /* State Variables */
    Proposal public proposalContract;
    //LagoonToken public lagoonToken;

    // Struct to store vote
    struct Vote {
        bool support; // true = votesFor and false = votesAgainst
        address voter;
    }

    // Struct to vote for or against
    struct ProposalVote {
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // Maps proposal ID to its votes
    mapping(uint256 => ProposalVote) public proposalVotes; 

    /* Events */
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool passed);

    constructor(address _proposalContractAddress) {
        proposalContract = Proposal(_proposalContractAddress);
        //lagoonToken = LagoonToken(_lagoonTokenAddress);
    }

    modifier proposalExists(uint256 proposalId) {
        Proposal.ProposalDetails memory proposal = proposalContract.getProposal(proposalId);
        require(proposal.beneficiary != address(0), "Proposal does not exist");
        _;
    }

    /// @dev Initializes voting
    /// @param proposalId The proposal's ID
    /// @param support If chooses to vote for
    function vote(uint256 proposalId, bool support) external proposalExists(proposalId) {
    ProposalVote storage proposalVote = proposalVotes[proposalId];
    require(!proposalVote.executed, "Proposal already executed");

    Proposal.ProposalDetails memory proposalDetails = proposalContract.getProposal(proposalId);
    //require(block.timestamp <= proposalDetails.creationTime + 7 days, "Voting period has ended");
    require(!proposalVote.hasVoted[msg.sender], "You have already voted on this proposal");

    //uint256 lagoonBalance = lagoonToken.balanceOf(msg.sender);
    //require(lagoonBalance > 0, "Insufficient Lagoon tokens to vote");

    // Calculate the 10% of Lagoon tokens
    //uint256 lagoonToBurn = lagoonBalance / 10;

    // Burn 10% of Lagoon tokens from the voter's balance
    //lagoonToken.burn(msg.sender, lagoonToBurn);

    proposalVote.hasVoted[msg.sender] = true;

    if (support) {
        proposalVote.votesFor++;
    } else {
        proposalVote.votesAgainst++;
    }

    emit Voted(proposalId, msg.sender, support);
    }


    /// @dev Executes the proposal after the voting period ends.
    /// @param proposalId The proposal's ID
    function executeProposal(uint256 proposalId) external proposalExists(proposalId) {
        ProposalVote storage proposalVote = proposalVotes[proposalId];
        require(!proposalVote.executed, "Proposal has already been executed");

        Proposal.ProposalDetails memory proposalDetails = proposalContract.getProposal(proposalId);
        //require(block.timestamp > proposalDetails.creationTime + 7 days, "Voting period not ended");

        proposalVote.executed = true;
        bool passed = proposalVote.votesFor > proposalVote.votesAgainst;

        //if (passed) {
          //  proposalContract.approveProposalForDonations(proposalId);
        //}

        emit ProposalExecuted(proposalId, passed);
    }

    /// @dev To see the number of voters vote for or against
    /// @param proposalId The proposal's ID
    /// @return votesFor number of people vote for
    /// @return votesAgainst number of people vote against
    function getVotes(uint256 proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
        ProposalVote storage proposalVote = proposalVotes[proposalId];
        return (proposalVote.votesFor, proposalVote.votesAgainst);
    }
}
