// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
* @title LagoonNft - A contract that distributes Lagoon Nft 
* @notice This contract implements an NFT given for every waqf donation that they give
**/
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract lgnNft is ERC721Enumerable, Ownable {
    /* State Variables */
    uint256 private nextTokenId;
    mapping(uint256 => string) private tokenURIs;
    
    string[] private regularURIs;
    string[] private goldURIs;
    string[] private diamondURIs;

    /// @dev Initializes the contract with the ERC721.
    constructor() ERC721("LagoonNFT", "LGN") Ownable(msg.sender) {
        nextTokenId = 1;

        // Initialize the URI arrays
        regularURIs = ["https://example.com/metadata/regular1.json", "https://example.com/metadata/regular2.json" /*... add more NFTs*/];
        goldURIs = ["https://example.com/metadata/gold1.json", "https://example.com/metadata/gold2.json" /*... add more NFTs*/];
        diamondURIs = ["https://example.com/metadata/diamond1.json", "https://example.com/metadata/diamond2.json" /*... add more NFTs*/];
    }

    /// @dev Mint a new NFT with a trait based on the donation amount
    /// @param to The address of the recipient
    /// @param amount The donation amount
    function mintNFT(address to, uint256 amount) external onlyOwner {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        // Assign a trait based on the donation amount with some randomness
        string memory uri = getURIByAmount(amount);

        // Set the token URI based on the randomly selected URI
        tokenURIs[tokenId] = uri;

        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /// @dev Returns a random URI based on the donation amount and corresponding trait
    /// @param amount The donation amount
    /// @return The URI as a string
    function getURIByAmount(uint256 amount) internal view returns (string memory) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));

        if (amount <= 1100 * 10 ** 18) {
            return regularURIs[random % regularURIs.length];
        } else if (amount > 1100 * 10 ** 18 && amount <= 2200 * 10 ** 18) {
            return goldURIs[random % goldURIs.length];
        } else {
            return diamondURIs[random % diamondURIs.length];
        }
    }

    /// @dev Set the token URI for a given token
    /// @param tokenId The ID of the token
    /// @param _tokenURI The URI to assign
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        tokenURIs[tokenId] = _tokenURI;
    }

    /// @dev Get the token URI for a given token
    /// @param tokenId The ID of the token
    /// @return The token URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId];
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
