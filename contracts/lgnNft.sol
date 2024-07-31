// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
* @title LagoonNft - A contract that distributes Lagoon Nft 
* @notice This contract implements a nft given for every waqf donation that they give
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract lgnNft is ERC721URIStorage {
    uint256 private _tokenIds;
    
    string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    constructor() ERC721("Lagoon", "LGN") {}

    /// @dev MintNFT
    /// @param recipient as the NFT receiver
    /// @param lagoonType a string indicating Regular, Gold and Diamond
    /// @return uint256 return new tokenId
    function mintNFT(address recipient, string memory lagoonType) public returns (uint256) {
        require(
            keccak256(bytes(lagoonType)) == keccak256(bytes("Regular")) ||
            keccak256(bytes(lagoonType)) == keccak256(bytes("Gold")) ||
            keccak256(bytes(lagoonType)) == keccak256(bytes("Diamond")),
            "Invalid Lagoon type"
        );

        _tokenIds += 1;
        uint256 newItemId = _tokenIds; //To get new unique TokenId

        string memory finalSvg = string(
            abi.encodePacked(baseSvg, lagoonType, "</text></svg>")
        );

        // Generate JSON metadata and base64 encode it
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', lagoonType,
                        ' Lagoon", "description": "On-chain Lagoon NFTs", "attributes": [{"trait_type": "Type", "value": "',
                        lagoonType,
                        '"}], "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        // Construct the token URI
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        // Mint the newNFT
        _mint(recipient, newItemId);
        // Set the token URI for the new NFT
        _setTokenURI(newItemId, finalTokenUri);

        return newItemId;
    }
}
