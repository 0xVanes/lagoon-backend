// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface untuk Proposal contract
interface IProposal {
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        uint256 themeId,
        string calldata title,
        string calldata description,
        uint256 amount,
        uint256 balance,
        address beneficiary,
        bool executed,
        uint256 creationTime
    );
    function getProposalStatus(uint256 _proposalId) external view returns (bool executed, bool expired);
}

// Interface untuk Token contract
interface IToken {
    function balanceOf(address account) external view returns (uint256);
}

// VotingSystem contract
contract VotingSystem {
    IProposal public proposalContract; // Address dari proposal contract
    IToken public tokenContract; // Address dari Token contract
    uint256 public minimumHolding; // Minimum token yang dibutuhkan untuk vote
    address public owner;

    uint256 public constant VOTING_DURATION = 1 weeks; // durasi 1 minggu

    struct Vote {
        address voter;
        bool inFavor; // true = support, false = oppose
    }

    struct ProposalVoteDetails {
        uint256 endTime;
        mapping(address => bool) hasVoted;
        uint256 supportCount;
        uint256 opposeCount;
    }

    mapping(uint256 => ProposalVoteDetails) public proposalVotesById;

    event VoteCasted(uint256 proposalId, address voter, bool inFavor);
    event ProposalExecuted(uint256 proposalId, bool success);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier hasEnoughTokens(address _voter) {
        require(tokenContract.balanceOf(_voter) >= minimumHolding, "Insufficient tokens");
        _;
    }

    modifier hasNotVoted(uint256 _proposalId) {
        require(!proposalVotesById[_proposalId].hasVoted[msg.sender], "Address has already voted");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setProposalContract(address _proposalAddress) external onlyOwner {
        proposalContract = IProposal(_proposalAddress);
    }

    function setTokenContract(address _tokenAddress) external onlyOwner {
        tokenContract = IToken(_tokenAddress);
    }

    function setMinimumHolding(uint256 _newMinimumHolding) external onlyOwner {
        minimumHolding = _newMinimumHolding;
    }

    function vote(uint256 _proposalId, bool _inFavor) external hasEnoughTokens(msg.sender) hasNotVoted(_proposalId) {
        (bool executed, bool expired) = proposalContract.getProposalStatus(_proposalId);
        require(!executed, "Proposal already executed");
        require(!expired, "Proposal has expired");

        ProposalVoteDetails storage voteDetails = proposalVotesById[_proposalId];
        
        if (voteDetails.endTime == 0) {
            voteDetails.endTime = block.timestamp + VOTING_DURATION;
        }
        require(block.timestamp < voteDetails.endTime, "Voting period has ended");

        voteDetails.hasVoted[msg.sender] = true;

        if (_inFavor) {
            voteDetails.supportCount++;
        } else {
            voteDetails.opposeCount++;
        }

        emit VoteCasted(_proposalId, msg.sender, _inFavor);
    }

    function executeProposal(uint256 _proposalId) external {
        ProposalVoteDetails storage voteDetails = proposalVotesById[_proposalId];
        (bool executed, bool expired) = proposalContract.getProposalStatus(_proposalId);
        require(!executed, "Proposal already executed");
        require(block.timestamp >= voteDetails.endTime, "Voting period has not ended");
        
        // Add logic to determine if proposal should be executed based on votes
        bool shouldExecute = voteDetails.supportCount > voteDetails.opposeCount;

        if (shouldExecute) {
            // Implement execution logic here (e.g., transfer funds, change state, etc.)
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    function getVotesByProposal(uint256 _proposalId) external view returns (uint256 supportCount, uint256 opposeCount) {
        ProposalVoteDetails storage voteDetails = proposalVotesById[_proposalId];
        return (voteDetails.supportCount, voteDetails.opposeCount);
    }
}
