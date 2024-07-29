// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
* @title LagoonToken - A token contract that distributes Lagoon Token
* @author 
* @notice This contract implements a token given for every waqf donation that they give
*/

contract LagoonToken is ERC20, ERC20Permit, Ownable {
    using SafeMath for uint256;

    /* Constants */
    uint256 private constant PERCENTAGE_DENOMINATOR = 1000; // Denominator for percentage calculation
    
    /* State Variables */
    uint256 public regularPercentage = 25; // Represents 2.5% (as before, divided by 1000 later)
    uint256 public goldPercentage = 50; // Represents 5% (as before, divided by 1000 later)
    uint256 public diamondPercentage = 100; // Represents 10% (as before, divided by 1000 later)
    uint256 public distributedLagoon; // Total tokens distributed as Lagoon

    // Default Lagoon address for users who haven't set their own
    address public defaultLagoonAddress;
    mapping(address => address) private userLagoonRecipients;
    
    // Lagoon distribution per user
    mapping(address => uint256) private lagoonDistributionPerUser;

    /* Events */
    event LagoonRecipientSet(address indexed user, address indexed recipient);
    event DefaultLagoonAddressSet(address indexed newDefaultLagoonAddress);
    event LagoonPercentageSet(uint256 newPercentage);

    /// @dev Initializes the contract with the provided token name, symbol, and default Lagoon address.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param _defaultLagoonAddress The default Lagoon recipient address.
    constructor(string memory name, string memory symbol, address _defaultLagoonAddress) ERC20(name, symbol) ERC20Permit(name) {
        require(_defaultLagoonAddress != address(0), "Address cannot be zero address");
        defaultLagoonAddress = _defaultLagoonAddress;

        // Mint initial tokens to the contract creator
        _mint(msg.sender, 1000 ether);
    }

    /// @dev Transfers tokens to the specified recipient, distributing lagoon.
    /// @param recipient The address to receive the tokens.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean indicating the success of the transfer.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 lagoonAmount = _calculateLagoon(amount);
        uint256 transferAmount = amount.sub(lagoonAmount);

        address lagoonRecipient = getUserLagoonRecipient(msg.sender);
        _transfer(msg.sender, lagoonRecipient, lagoonAmount);
        _updateLagoonDistribution(lagoonRecipient, lagoonAmount);

        return super.transfer(recipient, transferAmount);
    }

    /// @dev Transfers tokens from the sender to the recipient, distributing lagoon.
    /// @param sender The address from which the tokens are sent.
    /// @param recipient The address to receive the tokens.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean indicating the success of the transfer.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 lagoonAmount = _calculateLagoon(amount);
        uint256 transferAmount = amount.sub(lagoonAmount);

        address lagoonRecipient = getUserLagoonRecipient(sender);
        _transfer(sender, lagoonRecipient, lagoonAmount);
        _updateLagoonDistribution(lagoonRecipient, lagoonAmount);

        return super.transferFrom(sender, recipient, transferAmount);
    }

    /// @dev Calculates the lagoon amount for a given token transfer amount.
    /// @param _amount The token transfer amount.
    /// @return The calculated lagoon amount.
    function _calculateLagoon(uint256 _amount) internal view returns (uint256) {
        if (_amount <= 1100) {
            return _amount.mul(regularPercentage).div(PERCENTAGE_DENOMINATOR);
        } else if (_amount > 1100 && _amount < 2200) {
            return _amount.mul(goldPercentage).div(PERCENTAGE_DENOMINATOR);
        } else {
            return _amount.mul(diamondPercentage).div(PERCENTAGE_DENOMINATOR);
        }
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

    /// @dev Sets the new lagoon percentage.
    /// @param _newPercentage The new lagoon percentage value.
    function setLagoonPercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage <= PERCENTAGE_DENOMINATOR, "Percentage cannot be more than 100%");
        require(_newPercentage != 0, "Percentage cannot be zero");
        lagoonPercentage = _newPercentage;
        emit LagoonPercentageSet(_newPercentage);
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
        distributedLagoon = distributedLagoon.add(amount);
        lagoonDistributionPerUser[recipient] = lagoonDistributionPerUser[recipient].add(amount);
    }
}
