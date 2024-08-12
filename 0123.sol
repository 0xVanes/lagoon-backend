// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proposal {
    address public owner;
    uint256 private nextThemeId;
    uint256 private nextProposalId;
    uint256 private constant DURATION = 30 days; // Durasi tetap satu bulan

    // Struct to store proposal details
    struct ProposalDetails {
        uint256 id;
        uint256 themeId;
        string title;
        string description;
        uint256 amount;
        uint256 balance;
        address beneficiary;
        bool executed;
        uint256 creationTime; // Timestamp when the proposal was created
    }

    // Store themes and proposals
    mapping(uint256 => string) public themes;
    mapping(uint256 => ProposalDetails) private proposals;
    mapping(uint256 => uint256[]) private proposalsByTheme;

    event ThemeCreated(uint256 themeId, string themeName);
    event ProposalCreated(uint256 proposalId, uint256 themeId, string title, string description, uint256 amount, address beneficiary);
    event FundsDeposited(uint256 proposalId, address donor, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address withdrawer, uint256 amount);
    event ProposalDeleted(uint256 proposalId);
    event DonationMade(address donor, uint256 amount);

    constructor() {
        owner = msg.sender;
        nextThemeId = 1; // Start theme IDs from 1
        nextProposalId = 1; // Start proposal IDs from 1
    }

    function createTheme(string memory _themeName) external {
        require(msg.sender == owner, "Only owner can create themes");
        themes[nextThemeId++] = _themeName;
        emit ThemeCreated(nextThemeId - 1, _themeName);
    }

    function createProposal(
        uint256 _themeId,
        string memory _title,
        string memory _description,
        uint256 _amount,
        address _beneficiary
    ) external returns (uint256) {
        require(bytes(themes[_themeId]).length > 0, "Theme does not exist");

        ProposalDetails storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.themeId = _themeId;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.balance = 0;
        newProposal.beneficiary = _beneficiary;
        newProposal.executed = false;
        newProposal.creationTime = block.timestamp;

        proposalsByTheme[_themeId].push(nextProposalId);
        emit ProposalCreated(nextProposalId, _themeId, _title, _description, _amount, _beneficiary);

        return nextProposalId++;
    }

    function deposit(uint256 _proposalId) external payable {
        ProposalDetails storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(msg.value > 0, "Must send some ether");
        require(block.timestamp < proposal.creationTime + DURATION, "Deposit period has ended");

        proposal.balance += msg.value;
        emit FundsDeposited(_proposalId, msg.sender, msg.value);
    }

    function withdraw(uint256 _proposalId) external {
        ProposalDetails storage proposal = proposals[_proposalId];
        require(proposal.balance > 0, "No funds to withdraw");
        require(msg.sender == owner || msg.sender == proposal.beneficiary, "Not authorized to withdraw");
        require(block.timestamp >= proposal.creationTime + DURATION, "Proposal duration has not passed yet");

        uint256 amount = proposal.balance;
        proposal.balance = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(_proposalId, msg.sender, amount);
        proposal.executed = true;
    }

    function donate() external payable {
        require(msg.value > 0, "Must send some ether");
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Donation failed");

        emit DonationMade(msg.sender, msg.value);
    }

    function getProposal(uint256 _proposalId) external view returns (ProposalDetails memory) {
        return proposals[_proposalId];
    }

    function getProposalsByTheme(uint256 _themeId) external view returns (ProposalDetails[] memory) {
        uint256[] memory proposalIds = proposalsByTheme[_themeId];
        ProposalDetails[] memory result = new ProposalDetails[](proposalIds.length);

        for (uint256 i = 0; i < proposalIds.length; i++) {
            result[i] = proposals[proposalIds[i]];
        }

        return result;
    }

    function getProposalStatus(uint256 _proposalId) external view returns (bool executed, bool expired) {
        ProposalDetails storage proposal = proposals[_proposalId];
        return (proposal.executed, block.timestamp >= proposal.creationTime + DURATION);
    }
    
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
