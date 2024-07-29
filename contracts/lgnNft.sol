// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
* @title LagoonNft - A contract that distributes Lagoon Nft
* @author 
* @notice This contract implements a nft given for every waqf donation that they give
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

contract lgnNft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    constructor() ERC721("Lagoon", "LGN") {}

    function mintNFT(address recipient, string memory lagoonType) public returns (uint256) {
        require(
            keccak256(bytes(lagoonType)) == keccak256(bytes("Regular")) ||
            keccak256(bytes(lagoonType)) == keccak256(bytes("Gold")) ||
            keccak256(bytes(lagoonType)) == keccak256(bytes("Diamond")),
            "Invalid Lagoon type"
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

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

        // Prepend data:application/json;base64, to the data
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, finalTokenUri);

        return newItemId;
    }
}
