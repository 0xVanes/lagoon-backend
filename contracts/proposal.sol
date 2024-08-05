// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
* @title Proposal - A contract to make donation proposals and to donate to beneficiary
* @notice This contract prepares the proposals and handle giving the raised money to the beneficiary directly
**/

import "./lgnNft.sol";
import "./lagoonToken.sol";

contract Proposal {
    /* State Variables */
    address public owner; // Owner is the one who deploy the contract
    uint256 private nextThemeId; //Currently the theme is about Mosque, this is to add more donation themes
    uint256 private nextProposalId; //The ID number of the proposal
    uint256 private constant DURATION = 30 days; // The duration of the proposal

    lgnNft private nftContract;
    lagoonToken private tokenContract;

    // Struct to store proposal details
    struct ProposalDetails {
        uint256 id;
        uint256 themeId;
        string title;
        string description;
        uint256 amount; //The goal of the donation
        uint256 balance; //The raised donation
        address beneficiary;
        bool executed;
        uint256 creationTime; // Timestamp when the proposal was created
    }

    // theme ID to name of themes
    mapping(uint256 => string) public themes;

    // proposal ID to proposal details
    mapping(uint256 => ProposalDetails) private proposals;

    // proposal theme ID to proposal ID
    mapping(uint256 => uint256[]) private proposalsByTheme;

    // Mapping for last token distribution time
    mapping(address => uint256) private lastDistributionTime;

    /* Events */
    event ThemeCreated(uint256 themeId, string themeName);
    event ProposalCreated(uint256 proposalId, uint256 themeId, string title, string description, uint256 amount, address beneficiary);
    event FundsDeposited(uint256 proposalId, address donor, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address withdrawer, uint256 amount);
    event ProposalDeleted(uint256 proposalId);

    constructor(address _nftContractAddress, address _tokenContractAddress) {
        owner = msg.sender;
        nextThemeId = 1; // Start theme IDs from 1.
        nextProposalId = 1; // Start proposal IDs from 1.
        nftContract = lgnNft(_nftContractAddress);
        tokenContract = lagoonToken(_tokenContractAddress);
    }

    /// @dev Initializes the creation of new theme.
    /// @param _themeName The name of the theme.
    function createTheme(string memory _themeName) external {
        require(msg.sender == owner, "Only owner can create themes");
        themes[nextThemeId] = _themeName;
        emit ThemeCreated(nextThemeId, _themeName);
        nextThemeId++;
    }

    /// @dev Initializes the contract with the provided token name, symbol, and default Lagoon address.
    /// @param _themeId The ID of the theme.
    /// @param _title The title of the donation proposal.
    /// @param _description The description of the proposal.
    /// @param _amount The goal in ISLM of the donation.
    /// @param _beneficiary The address of the beneficiary.
    function createProposal(uint256 _themeId, string memory _title, string memory _description, uint256 _amount, address _beneficiary) external{
        require(_themeId > 0 && _themeId < nextThemeId, "Theme does not exist");

        //Insert all the information needed on a newProposal.
        ProposalDetails memory newProposal = ProposalDetails({
            id: nextProposalId,
            themeId: _themeId,
            title: _title,
            description: _description,
            amount: _amount,
            balance: 0,
            beneficiary: _beneficiary,
            executed: false,
            creationTime: block.timestamp
        });

        //Store a new proposal for easier retrieval with the themeId and proposal ID.
        proposals[nextProposalId] = newProposal;
        proposalsByTheme[_themeId].push(nextProposalId);

        emit ProposalCreated(nextProposalId, _themeId, _title, _description, _amount, _beneficiary);
        nextProposalId++;
    }

    /// @dev The fund will be held in the smart contract until it is withdrawn.
    /// @param _proposalId The ID of the proposal.
    function deposit(uint256 _proposalId) external payable {
        ProposalDetails storage proposal = proposals[_proposalId]; //Declares a storage reference.
        require(!proposal.executed, "Proposal already executed");
        require(msg.value > 0, "Must send some ether");
        require(block.timestamp < proposal.creationTime + DURATION, "Deposit period has ended");

        proposal.balance += msg.value;
        emit FundsDeposited(_proposalId, msg.sender, msg.value);
        distributeRewards(msg.sender, msg.value);
    }

    /// @dev Distributes NFT and tokens to the user.
    /// @param donor The address of the donor.
    /// @param amount The donation amount.
    function distributeRewards(address donor, uint256 amount) internal {
        // Determine the lagoon type based on the amount
        string memory lagoonType = getLagoonType(amount);

        // Check if token distribution is allowed
        if (block.timestamp >= lastDistributionTime[donor] + 30 days) {
            // Mint NFT to the donor
            nftContract.mintNFT(donor, lagoonType);
            // Distribute tokens to the donor
            tokenContract.distributeTokens(donor, amount);
            lastDistributionTime[donor] = block.timestamp;
        }
    }

    /// @dev Determines the lagoon type based on the donation amount.
    /// @param amount The donation amount.
    /// @return The lagoon type as a string.
    function getLagoonType(uint256 amount) internal pure returns (string memory) {
        if (amount <= 1100 * 10 ** 18) {
            return "Regular";
        } else if (amount > 1100 * 10 ** 18 && amount < 2200 * 10 ** 18) {
            return "Gold";
        } else {
            return "Diamond";
        }
    }

    /// @dev The fund will be held in the smart contract until it is withdrawn.
    /// @param _proposalId The ID of the proposal.
    function withdraw(uint256 _proposalId) external {
        ProposalDetails storage proposal = proposals[_proposalId]; //Declares a storage reference.
        require(proposal.balance > 0, "No funds to withdraw");
        require(msg.sender == owner || msg.sender == proposal.beneficiary, "Not authorized to withdraw");
        require(block.timestamp >= proposal.creationTime + DURATION, "Proposal duration has not passed yet");

        uint256 amount = proposal.balance;
        proposal.balance = 0;
        // Use call for transferring funds.
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(_proposalId, msg.sender, amount);

        // Mark the proposal as executed once the funds are withdrawn.
        proposal.executed = true;
    }

    /// @dev Gets the proposal
    /// @param _proposalId The proposal ID.
    /// @return The ProposalDetails
    function getProposal(uint256 _proposalId) external view returns (ProposalDetails memory) {
        return proposals[_proposalId];
    }

    /// @dev Gets the proposal by their theme
    /// @param _themeId The theme ID.
    /// @return The proposal Detail by their theme
    function getProposalsByTheme(uint256 _themeId) external view returns (ProposalDetails[] memory) {
        uint256[] storage proposalIds = proposalsByTheme[_themeId]; //Accesses the mapping proposalByTheme
        ProposalDetails[] memory result = new ProposalDetails[](proposalIds.length);
        
        for (uint256 i = 0; i < proposalIds.length; i++) {
            result[i] = proposals[proposalIds[i]];
        }
        return result;
    }

    /// @dev To know the status of the proposal
    /// @param _proposalId The proposal's ID
    function getProposalStatus(uint256 _proposalId) external view returns (bool executed, bool expired) {
        ProposalDetails storage proposal = proposals[_proposalId];
        bool isExpired = block.timestamp >= proposal.creationTime + DURATION;
        return (proposal.executed, isExpired);
    }

    /// @dev To delete the proposal before voting begin (Not Now)
    /// @param _proposalId The proposal ID.
    function deleteProposal(uint256 _proposalId) external {
        ProposalDetails storage proposal = proposals[_proposalId];
        require(msg.sender == owner, "Only owner can delete proposal");
        require(!proposal.executed, "Cannot delete executed proposal");
        delete proposals[_proposalId];
        
        uint256[] storage themeProposals = proposalsByTheme[proposal.themeId];
        for (uint256 i = 0; i < themeProposals.length; i++) {
            if (themeProposals[i] == _proposalId) {
                themeProposals[i] = themeProposals[themeProposals.length - 1];
                themeProposals.pop();
                break;
            }
        }
        emit ProposalDeleted(_proposalId);
    }
}