// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Proposal {
    address public owner;
    uint256 public nextThemeId;
    uint256 public nextProposalId;

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
    }

    // Store themes and proposals
    mapping(uint256 => string) public themes;
    mapping(uint256 => ProposalDetails) public proposals;
    mapping(uint256 => uint256[]) public proposalsByTheme;

    event ThemeCreated(uint256 themeId, string themeName);
    event ProposalCreated(uint256 proposalId, uint256 themeId, string title, string description, uint256 amount, address beneficiary);
    event FundsDeposited(uint256 proposalId, address donor, uint256 amount);
    event ProposalExecuted(uint256 proposalId);

    constructor() {
        owner = msg.sender;
        nextThemeId = 1; // Start theme IDs from 1
        nextProposalId = 1; // Start proposal IDs from 1
    }

    function createTheme(string memory _themeName) external {
        require(msg.sender == owner, "Only owner can create themes");
        themes[nextThemeId] = _themeName;
        emit ThemeCreated(nextThemeId, _themeName);
        nextThemeId++;
    }

    function createProposal(
        uint256 _themeId,
        string memory _title,
        string memory _description,
        uint256 _amount,
        address _beneficiary
    ) external returns (uint256) {
        require(bytes(themes[_themeId]).length > 0, "Theme does not exist");

        ProposalDetails memory newProposal = ProposalDetails({
            id: nextProposalId,
            themeId: _themeId,
            title: _title,
            description: _description,
            amount: _amount,
            balance: 0,
            beneficiary: _beneficiary,
            executed: false
        });

        proposals[nextProposalId] = newProposal;
        proposalsByTheme[_themeId].push(nextProposalId);

        emit ProposalCreated(nextProposalId, _themeId, _title, _description, _amount, _beneficiary);
        nextProposalId++;

        return nextProposalId - 1; // Return the ID of the newly created proposal
    }

    function deposit(uint256 _proposalId) external payable {
        ProposalDetails storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(msg.value > 0, "Must send some ether");

        proposal.balance += msg.value;
        emit FundsDeposited(_proposalId, msg.sender, msg.value);
    }

    function execute(uint256 _proposalId) external {
        ProposalDetails storage proposal = proposals[_proposalId];
        require(msg.sender == owner, "Only owner can execute");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.balance >= proposal.amount, "Insufficient balance to execute");

        proposal.executed = true;
        payable(proposal.beneficiary).transfer(proposal.amount);
        proposal.balance -= proposal.amount;

        emit ProposalExecuted(_proposalId);
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
}