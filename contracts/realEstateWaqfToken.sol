// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract realEstateAssetTokenization {
    // Define necessary state variables and mappings
    uint public proposalCount;
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public votes; // Declare the votes mapping
    mapping(address => uint) public landTokenBalance;
    mapping(address => uint) public dividends;
    address public nazir;
    address[] public investors;  // Store the list of investor addresses

    struct Proposal {
        uint id;
        string description;
        uint priceInRupiah;
        bool approved;
        uint totalVotes;
        uint supportVotes;
        uint tokenSupply;
    }

    // Events
    event ProposalCreated(uint proposalId, string description);
    event Voted(uint proposalId, address voter, bool support);
    event TokenConverted(uint proposalId, uint amount);
    event Invested(uint proposalId, address investor, uint amount);
    event DividendsDistributed(uint proposalId, uint amount);
    event TokensSold(uint proposalId, address seller, uint amount);
    event DividendsBurned(uint proposalId, uint amount);

    // Constructor to set the Nazir address
    constructor(address _nazir) {
        nazir = _nazir;
    }

    // Proposal Creation
    function createProposal(string memory description, uint priceInRupiah) public {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            priceInRupiah: priceInRupiah,
            approved: false,
            totalVotes: 0,
            supportVotes: 0,
            tokenSupply: 0
        });
        emit ProposalCreated(proposalCount, description);
    }

    // Governance Voting
    function voteOnProposal(uint proposalId, bool support) public {
        require(proposals[proposalId].id == proposalId, "Proposal does not exist.");
        require(votes[proposalId][msg.sender] == false, "You have already voted.");  // Ensure that votes mapping is properly declared and referenced

        Proposal storage proposal = proposals[proposalId];
        votes[proposalId][msg.sender] = true;
        proposal.totalVotes++;

        if (support) {
            proposal.supportVotes++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    // Nazir Payment and Token Conversion
    function convertToToken(uint proposalId) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.supportVotes > proposal.totalVotes / 2, "Proposal not approved by majority.");
        require(msg.sender == nazir, "Only Nazir can convert to tokens.");
        
        proposal.approved = true;
        uint256 amount = proposal.priceInRupiah;
        proposal.priceInRupiah = 0;
        proposal.tokenSupply = amount;
        landTokenBalance[nazir] += proposal.tokenSupply;

        emit TokenConverted(proposalId, proposal.tokenSupply);
    }

    // Investor Payments and Token Distribution
    function invest(uint proposalId, uint amount) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.approved == true, "Proposal not approved.");
        
        if (landTokenBalance[msg.sender] == 0) {
            investors.push(msg.sender);  // Add to investors list if not already an investor
        }

        landTokenBalance[msg.sender] += amount;
        landTokenBalance[nazir] -= amount;

        emit Invested(proposalId, msg.sender, amount);
    }

    // Dividend Distribution
    function distributeDividends(uint proposalId, uint256 percentageDividend) public {
    require(msg.sender == nazir, "Only Nazir can distribute dividends.");
    Proposal storage proposal = proposals[proposalId];
    uint256 dividendAmount = proposal.tokenSupply / percentageDividend; // Example dividend calculation

    // Mint new tokens for the dividend distribution
    for (uint i = 0; i < investors.length; i++) {
        address investor = investors[i];
        uint share = (landTokenBalance[investor] * dividendAmount) / proposal.tokenSupply;
        landTokenBalance[investor] += share;
        proposal.tokenSupply += share; // Increase the total supply to reflect the minted tokens
    }

    emit DividendsDistributed(proposalId, dividendAmount);
}


    // Token Sale and Dividend Burning
    function sellTokens(uint proposalId, uint amount) public {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender != nazir, "You are the nazir, You cannot sell your tokens. Must he voted first");
        require(landTokenBalance[msg.sender] >= amount, "Insufficient token balance.");
        
        landTokenBalance[msg.sender] -= amount;
        landTokenBalance[nazir] += amount;

        // Burn the corresponding dividends
        dividends[msg.sender] -= (dividends[msg.sender] * amount) / proposal.tokenSupply;

        emit TokensSold(proposalId, msg.sender, amount);
        emit DividendsBurned(proposalId, dividends[msg.sender]);
    }
}
