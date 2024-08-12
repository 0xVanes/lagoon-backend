// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateWaqfToken is ERC20, Ownable {
    uint256 public totalShares;
    uint256 public incomeGenerated;
    mapping(address => uint256) public sharesOwned;
    address[] public tokenHolders; // Array to store token holders

    event IncomeDistributed(uint256 amount, uint256 timestamp);

    // Constructor for the RealEstateWaqfToken
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        totalShares = initialSupply;
        tokenHolders.push(msg.sender); // Add the deployer to the list of token holders
    }

    // Override the transfer function to track token holders
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _updateTokenHolders(_msgSender(), recipient, amount);
        return super.transfer(recipient, amount);
    }

    // Override the transferFrom function to track token holders
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _updateTokenHolders(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    // Function to distribute income to token holders based on their shares
    function distributeIncome() external payable onlyOwner {
        require(msg.value > 0, "No income to distribute");

        incomeGenerated += msg.value;
        uint256 incomePerShare = msg.value / totalShares;

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            address holder = tokenHolders[i];
            uint256 shares = balanceOf(holder);
            uint256 payment = shares * incomePerShare;
            payable(holder).transfer(payment);
        }

        emit IncomeDistributed(msg.value, block.timestamp);
    }

    // Function to allow the owner to allocate shares to a new beneficiary
    function allocateShares(address beneficiary, uint256 amount) external onlyOwner {
        _mint(beneficiary, amount);
        sharesOwned[beneficiary] += amount;
        totalShares += amount;

        if (balanceOf(beneficiary) > 0 && !_isHolder(beneficiary)) {
            tokenHolders.push(beneficiary); // Add to token holders if not already added
        }
    }

    // Function to allow the owner to revoke shares from a beneficiary
    function revokeShares(address beneficiary, uint256 amount) external onlyOwner {
        require(sharesOwned[beneficiary] >= amount, "Insufficient shares to revoke");
        _burn(beneficiary, amount);
        sharesOwned[beneficiary] -= amount;
        totalShares -= amount;

        if (balanceOf(beneficiary) == 0) {
            _removeHolder(beneficiary); // Remove from token holders if balance is zero
        }
    }

    // Internal function to update token holders list
    function _updateTokenHolders(address from, address to, uint256 amount) internal {
        if (balanceOf(to) == 0 && amount > 0) {
            tokenHolders.push(to); // Add new token holder to the list
        }

        if (balanceOf(from) == amount && amount > 0) {
            _removeHolder(from); // Remove from the list if transferring all tokens
        }
    }

    // Internal function to remove an address from the tokenHolders array
    function _removeHolder(address holder) internal {
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            if (tokenHolders[i] == holder) {
                tokenHolders[i] = tokenHolders[tokenHolders.length - 1];
                tokenHolders.pop();
                break;
            }
        }
    }

    // Internal function to check if an address is a token holder
    function _isHolder(address holder) internal view returns (bool) {
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            if (tokenHolders[i] == holder) {
                return true;
            }
        }
        return false;
    }
}
