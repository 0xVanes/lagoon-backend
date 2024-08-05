// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
* @title LagoonToken - A token contract that distributes Lagoon Token
* @notice This contract implements a token given for every waqf donation that they give
**/

contract LagoonToken is ERC20, ERC20Permit, Ownable {

    /* State Variables */
    uint256 public constant REGULAR_TOKEN_AMOUNT = 10 * 10 ** 18; // 10 tokens given for regular
    uint256 public constant GOLD_TOKEN_AMOUNT = 20 * 10 ** 18;    // 20 tokens given for gold
    uint256 public constant DIAMOND_TOKEN_AMOUNT = 50 * 10 ** 18; // 50 tokens given for diamond
    uint256 public distributedLagoon; // Total tokens distributed as Lagoon
    uint256 public constant TOKEN_DISTRIBUTION_INTERVAL = 30 days; // The interval to get another Lagoon Token is 30 days
    bool private _reentrancyLock = false; // To prevent reentrancy

    // Default Lagoon address for users who haven't set their own
    address public defaultLagoonAddress;
    mapping(address => address) private userLagoonRecipients;
    
    // Lagoon distribution per user
    mapping(address => uint256) private lagoonDistributionPerUser;

    // Calculate the time after a user last Donated (they can get Lagoon token after 30 days)
    mapping(address => uint256) private lastDonationTime;

    /* Events */
    event LagoonRecipientSet(address indexed user, address indexed recipient);
    event DefaultLagoonAddressSet(address indexed newDefaultLagoonAddress);

    /// @dev Initializes the contract with the provided token name, symbol, and default Lagoon address.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param _defaultLagoonAddress The default Lagoon recipient address.
    constructor(string memory name, string memory symbol, address _defaultLagoonAddress) 
        ERC20(name, symbol) 
        ERC20Permit(name)
        Ownable(msg.sender) 
    {
        require(_defaultLagoonAddress != address(0), "Address cannot be zero address");
        defaultLagoonAddress = _defaultLagoonAddress;

        // Mint initial tokens to the contract creator
        _mint(msg.sender, 1000 ether);
    }

    /// @dev To Prevent Reentrancy call
    modifier nonReentrant(){
        require(!_reentrancyLock, "Reentrant call");
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }

    /// @dev Calculates the lagoon amount for a given token transfer amount.
    /// @param _amount The token transfer amount.
    /// @return The calculated lagoon amount.
    function _calculateLagoon(uint256 _amount) internal pure returns (uint256) {
        if (_amount <= 1100 * 10 ** 18) {
            return REGULAR_TOKEN_AMOUNT;
        } else if (_amount > 1100 * 10 ** 18 && _amount < 2200 * 10 ** 18) {
            return GOLD_TOKEN_AMOUNT;
        } else {
            return DIAMOND_TOKEN_AMOUNT;
        }
    }

    /// @dev Transfers tokens to the specified recipient, distributing lagoon token.
    /// @param recipient The address to receive the tokens.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean indicating the success of the transfer.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 lagoonAmount = _calculateLagoon(amount);
        address lagoonRecipient = getUserLagoonRecipient(msg.sender);

        // Distribute lagoon token to the lagoon recipient
        _mint(lagoonRecipient, lagoonAmount);
        _updateLagoonDistribution(lagoonRecipient, lagoonAmount);

        // Transfer the specified amount to the recipient
        return super.transfer(recipient, amount);
    }

    /// @dev Transfers tokens from the sender to the recipient, distributing lagoon.
    /// @param sender The address from which the tokens are sent.
    /// @param recipient The address to receive the tokens.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean indicating the success of the transfer.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 lagoonAmount = _calculateLagoon(amount);
        address lagoonRecipient = getUserLagoonRecipient(sender);

        // Distribute lagoon token to the lagoon recipient
        _mint(lagoonRecipient, lagoonAmount);
        _updateLagoonDistribution(lagoonRecipient, lagoonAmount);

        // Transfer the specified amount from sender to recipient
        return super.transferFrom(sender, recipient, amount);
    }

    /// @dev A function to distribute token with block.timestamp
    /// @param recipient as the recipient address
    /// @param amount as the number of Lagoon received
    function distributeTokens(address recipient, uint256 amount) external nonReentrant onlyOwner {
        require(block.timestamp >= lastDonationTime[recipient] + TOKEN_DISTRIBUTION_INTERVAL, "Token distribution not allowed yet");
        uint256 lagoonAmount = _calculateLagoon(amount);

        // Mint the calculated lagoon amount to the recipient
        _mint(recipient, lagoonAmount);
        _updateLagoonDistribution(recipient, lagoonAmount);
        lastDonationTime[recipient] = block.timestamp;
    }

    /// @dev Sets the lagoon recipient address for the calling user.
    /// @param _lagoonRecipient The new lagoon recipient address.
    function setUserLagoonRecipient(address _lagoonRecipient) public {
        require(_lagoonRecipient != address(0), "Address cannot be zero address");
        userLagoonRecipients[msg.sender] = _lagoonRecipient;
        emit LagoonRecipientSet(msg.sender, _lagoonRecipient);
    }

    /// @dev Retrieves the lagoon recipient address for a given user.
    /// @param _user The user's address.
    /// @return The lagoon recipient address.
    function getUserLagoonRecipient(address _user) public view returns (address) {
        address recipient = userLagoonRecipients[_user];
        return (recipient != address(0)) ? recipient : defaultLagoonAddress;
    }

    /// @dev Sets the default lagoon recipient address.
    /// @param _newDefaultLagoonAddress The new default lagoon recipient address.
    function setDefaultLagoonAddress(address _newDefaultLagoonAddress) public onlyOwner {
        require(_newDefaultLagoonAddress != address(0), "Address cannot be zero address");
        defaultLagoonAddress = _newDefaultLagoonAddress;
        emit DefaultLagoonAddressSet(_newDefaultLagoonAddress);
    }

    /// @dev Gets the total lagoon distributed to a user.
    /// @param _user The user's address.
    /// @return The total lagoon distributed to the user.
    function getLagoonDistributionPerUser(address _user) public view returns (uint256) {
        return lagoonDistributionPerUser[_user];
    }

    /// @dev Updates lagoon distribution details.
    /// @param recipient The lagoon recipient address.
    /// @param amount The amount of lagoon distributed.
    function _updateLagoonDistribution(address recipient, uint256 amount) internal {
        distributedLagoon += amount;
        lagoonDistributionPerUser[recipient] += amount;
    }
}
