// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
* @title Proposal - A contract to make donation proposals and to donate to beneficiary
* @notice This contract prepares the proposals and handles giving the raised money to the beneficiary directly
**/

import "./lgnNft.sol";
import "./lagoonToken.sol";

contract Proposal {
    /* State Variables */
    address public owner; // Owner is the one who deploys the contract
    uint256 public constant DURATION = 30 days; // The duration of the donation period
    uint256 private nextProposalId; // To track the next proposal ID
    uint256 public constant FEE_PERCENTAGE = 25; // 2.5% fee (2.5 * 10^1)

    lgnNft private nftContract;
    LagoonToken private tokenContract;

    // Struct to store proposal details
    struct ProposalDetails {
        uint256 id;
        string title;
        string description;
        uint256 amount; // The goal of the donation
        uint256 balance; // The raised donation
        address beneficiary;
        bool executed;
        uint256 creationTime; // Timestamp when the proposal was created
        bool approvedForDonations; // Flag to check if the proposal is approved for donations
    }

    // Struct to see the list of Donors
    struct Donor {
        address walletAddress;
        uint256 amount;
        uint256 time;
    }

    // Mapping for proposal ID to proposal details
    mapping(uint256 => ProposalDetails) private proposals;

    // Mapping for proposal ID to Donors
    mapping(uint256 => Donor[]) private proposalDonors;

    // Mapping for last token distribution time
    mapping(address => uint256) private lastDistributionTime;

    /* Events */
    event ProposalCreated(uint256 proposalId, string title, string description, uint256 amount, address beneficiary);
    event FundsDonated(uint256 proposalId, address donor, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address withdrawer, uint256 amount);
    event ProposalApprovedForDonations(uint256 proposalId);

    constructor(address _nftContractAddress, address _tokenContractAddress) {
        owner = msg.sender;
        nftContract = lgnNft(_nftContractAddress);
        tokenContract = LagoonToken(_tokenContractAddress);
        nextProposalId = 1; // Initialize the next proposal ID to start at 1
    }

    /// @dev Initializes the contract with the provided token name, symbol, and default Lagoon address.
    /// @param _title The title of the donation proposal.
    /// @param _description The description of the proposal.
    /// @param _amount The goal in ISLM of the donation.
    /// @param _beneficiary The address of the beneficiary.
    function createProposal(string memory _title, string memory _description, uint256 _amount, address _beneficiary) external payable {
        require(_amount > 0, "Amount should be greater than 0");
        // Insert all the information needed on a newProposal.
        ProposalDetails memory newProposal = ProposalDetails({
            id: nextProposalId,
            title: _title,
            description: _description,
            amount: _amount,
            balance: 0,
            beneficiary: _beneficiary,
            executed: false,
            creationTime: block.timestamp,
            approvedForDonations: false
        });

        // Store the new proposal
        proposals[nextProposalId] = newProposal;

        emit ProposalCreated(nextProposalId, _title, _description, _amount, _beneficiary);
        nextProposalId++;
    }

    function approveProposalForDonations(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
        ProposalDetails storage proposal = proposals[_proposalId];
        //require(block.timestamp >= proposal.creationTime + 7 days, "Voting period not ended");
        require(!proposal.approvedForDonations, "Proposal already approved for donations");
        proposal.approvedForDonations = true;

        emit ProposalApprovedForDonations(_proposalId);
    }

    function donate(uint256 _proposalId) external payable {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");

        ProposalDetails storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(msg.value > 0, "Must send some ether");
        //require(proposal.approvedForDonations, "Proposal not approved for donations");
        require(block.timestamp < proposal.creationTime + DURATION, "Donation period has ended");

        // Calculate and transfer the fee
        uint256 fee = (msg.value * FEE_PERCENTAGE) / 1000;
        uint256 donationAmount = msg.value - fee;
        payable(owner).transfer(fee);

        proposal.balance += donationAmount;

        // Store the donor's information
        Donor memory newDonor = Donor({
            walletAddress: msg.sender,
            amount: donationAmount,
            time: block.timestamp
        });
        proposalDonors[_proposalId].push(newDonor);

        emit FundsDonated(_proposalId, msg.sender, donationAmount);
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
        require(proposals[_proposalId].id != 0, "Invalid proposal ID"); // Check if proposal exists

        ProposalDetails storage proposal = proposals[_proposalId]; // Declares a storage reference.
        require(proposal.balance > 0, "No funds to withdraw");
        require(msg.sender == owner || msg.sender == proposal.beneficiary, "Not authorized to withdraw");
        //require(block.timestamp >= proposal.creationTime + DURATION, "Proposal duration has not passed yet");

        uint256 amount = proposal.balance;
        uint256 fee = (amount * FEE_PERCENTAGE) / 1000;
        uint256 withdrawAmount = amount - fee;
        proposal.balance = 0;

        // Use call for transferring funds.
        (bool success, ) = payable(owner).call{value: fee}("");
        require(success, "Fee transfer failed");

        (success, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(_proposalId, msg.sender, withdrawAmount);

        // Mark the proposal as executed once the funds are withdrawn.
        proposal.executed = true;
    }

    /// @dev To count how many donors donated
    /// @param _proposalId The proposal ID
    /// @return number of proposal's donor
    function getDonorCount(uint256 _proposalId) external view returns (uint256) {
        return proposalDonors[_proposalId].length;
    }

    /// @dev Gets the donor
    /// @param _proposalId The proposal ID
    function getDonors(uint256 _proposalId) external view returns (Donor[] memory) {
    return proposalDonors[_proposalId];
}

    /// @dev Returns the raised amount for a specific proposal.
    /// @param _proposalId The proposal ID.
    /// @return The raised amount in the proposal.
    function getRaisedAmount(uint256 _proposalId) external view returns (uint256) {
        require(proposals[_proposalId].id != 0, "Invalid proposal ID"); // Check if proposal exists
        return proposals[_proposalId].balance;
    }

    /// @dev Gets the proposal.
    /// @param _proposalId The proposal ID.
    /// @return The ProposalDetails.
    function getProposal(uint256 _proposalId) external view returns (ProposalDetails memory) {
        require(proposals[_proposalId].id != 0, "Invalid proposal ID"); // Check if proposal exists
        return proposals[_proposalId];
    }

    /// @dev To know the status of the proposal.
    /// @param _proposalId The proposal's ID.
    function getProposalStatus(uint256 _proposalId) external view returns (bool executed, bool expired) {
        require(proposals[_proposalId].id != 0, "Invalid proposal ID"); // Check if proposal exists

        ProposalDetails storage proposal = proposals[_proposalId];
        bool isExpired = block.timestamp >= proposal.creationTime + DURATION;
        return (proposal.executed, isExpired);
    }

    /// @dev Returns the total number of proposals created.
    function getProposalCount() external view returns (uint256) {
        return nextProposalId - 1; // Return the count of actual proposals since nextProposalId starts at 1.
    }
}
