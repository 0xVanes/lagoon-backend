// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RealEstateWaqfToken {
    struct Proposal {
        string description;
        uint256 landPrice;
        uint256 priceInUSD;
        address proposer;
        uint256 createdAt;
        uint256 voteValidatedAt;
        bool isValidated;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    event ProposalCreated(uint256 proposalId, string description, uint256 landPrice, uint256 priceInUSD, uint256 createdAt);
    event ProposalValidated(uint256 proposalId, uint256 voteValidatedAt);

    function addProposal(string memory _description, uint256 _landPrice, uint256 _priceInUSD) public {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            landPrice: _landPrice,
            priceInUSD: _priceInUSD,
            proposer: msg.sender,
            createdAt: block.timestamp,
            voteValidatedAt: 0,
            isValidated: false
        });
        emit ProposalCreated(proposalCount, _description, _landPrice, _priceInUSD, block.timestamp);
    }

    function validateVote(uint256 _proposalId) public {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can validate");
        require(!proposals[_proposalId].isValidated, "Proposal already validated");

        proposals[_proposalId].isValidated = true;
        proposals[_proposalId].voteValidatedAt = block.timestamp;
        emit ProposalValidated(_proposalId, block.timestamp);
    }

    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }
}
