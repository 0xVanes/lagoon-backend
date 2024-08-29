// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
* @title realEstateAssetTokenization - A contract to tokenize land waqf assets 
* @notice This contract tokenize land waqf assets through DAO system
**/

//import "./lagoonToken.sol";

contract realEstateAssetTokenization {
    /* State Variables */
    uint public proposalCount;
    address public nazir;
    address[] public investors;
    //LagoonToken public lagoonToken;

    // Struct to Land Token Proposal
    struct Proposal {
        uint id;
        string description;
        uint priceInRupiah;
        bool approved;
        uint totalVotes;
        uint supportVotes;
        uint tokenSupply;
        uint256 creationTime;
    }

    // Proposal ID per Proposal
    mapping(uint => Proposal) public proposals;
    // Proposal ID to Voter address to Voting Yes or No
    mapping(uint => mapping(address => bool)) public votes;
    // Investor to TokenBalance
    mapping(address => uint) public landTokenBalance;
    // Investor to Dividend
    mapping(address => uint) public dividends;

    /* Events */
    event ProposalCreated(uint proposalId, string description);
    event Voted(uint proposalId, address voter, bool support);
    event TokenConverted(uint proposalId, uint amount);
    event Invested(uint proposalId, address investor, uint amount);
    event DividendsDistributed(uint proposalId, uint amount);
    event TokensSold(uint proposalId, address seller, uint amount);
    event DividendsBurned(uint proposalId, uint amount);

    /// @dev Initialize who the nazir is
    /// @param _nazir The name of the token.
    constructor(address _nazir) {
        nazir = _nazir;
        //lagoonToken = LagoonToken(_lagoonTokenAddress);
    }

    /// @dev Create a Land Tokenization Proposal.
    /// @param description The Description of the Proposal.
    /// @param priceInRupiah The price of Land Asset in Rupiah.
    function createProposal(string memory description, uint priceInRupiah) public {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            priceInRupiah: priceInRupiah,
            approved: false,
            totalVotes: 0,
            supportVotes: 0,
            tokenSupply: 0,
            creationTime: block.timestamp
        });
        emit ProposalCreated(proposalCount, description);
    }

    /// @dev A voting system for Land Tokenization Proposal.
    /// @param proposalId The ID of the proposal
    /// @param support If the Token Holder support or oppose the proposal
    function voteOnProposal(uint proposalId, bool support) public {
        require(proposals[proposalId].id == proposalId, "Proposal does not exist.");
        require(votes[proposalId][msg.sender] == false, "You have already voted.");  
        //uint256 lagoonBalance = lagoonToken.balanceOf(msg.sender);
        //require(lagoonBalance > 0, "Insufficient Lagoon tokens to vote");

        Proposal storage proposal = proposals[proposalId];
        votes[proposalId][msg.sender] = true;
        proposal.totalVotes++;

        // Calculate the 10% of Lagoon tokens
        //uint256 lagoonToBurn = lagoonBalance / 10;

        // Burn 10% of Lagoon tokens from the voter's balance
        //lagoonToken.burn(msg.sender, lagoonToBurn);

        if (support) {
            proposal.supportVotes++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /// @dev Converting Fiat to Token 1:1
    /// @param proposalId The ID of the proposal
    function convertToToken(uint proposalId) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.supportVotes > proposal.totalVotes / 2, "Proposal not approved by majority.");
        require(msg.sender == nazir, "Only Nazir can convert to tokens.");
        //require(block.timestamp <= Proposal.creationTime + 7 days, "Voting period has ended");
        
        proposal.approved = true;
        uint256 amount = proposal.priceInRupiah;
        proposal.priceInRupiah = 0;
        proposal.tokenSupply = amount;
        landTokenBalance[nazir] += proposal.tokenSupply;

        emit TokenConverted(proposalId, proposal.tokenSupply);
    }

    /// @dev Investor Payments and Token Distribution.
    /// @param proposalId The ID of the proposal.
    /// @param amount The amount of Fiat to invest.
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

    /// @dev To give dividends to investors.
    /// @param proposalId The ID of the proposal.
    /// @param percentageDividend How many percent of each investor's token will be given as dividend.
    function distributeDividends(uint proposalId, uint256 percentageDividend) public {
    require(msg.sender == nazir, "Only Nazir can distribute dividends.");
    Proposal storage proposal = proposals[proposalId];
    uint256 dividendAmount = proposal.tokenSupply / percentageDividend; // Dividend calculation

    // Mint new tokens for the dividend distribution
    for (uint i = 0; i < investors.length; i++) {
        address investor = investors[i];
        uint share = (landTokenBalance[investor] * dividendAmount) / proposal.tokenSupply;
        landTokenBalance[investor] += share;
        proposal.tokenSupply += share; // Increase the total supply to reflect the minted tokens
    }

    emit DividendsDistributed(proposalId, dividendAmount);
}


    /// @dev Investor can sell the tokens to fiat.
    /// @param proposalId The ID of the proposal.
    /// @param amount The amount of token to fiat.
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
