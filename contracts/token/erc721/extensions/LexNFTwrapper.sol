// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../LexNFT.sol';
import '../../../interfaces/IERC20.sol';

/// @notice Extension for LexNFT that allows baskets of ERC-20 tokens to be deposited to mint NFT derivatives.
contract LexNFTwrapper is LexNFT {
    mapping(uint256 => Derivative) derivatives;

    struct Derivative {
        IERC20[] underlyingAssets;
        uint256[] amounts;
        string details;
    }

    constructor(string memory name, string memory symbol) LexNFT(name, symbol) {}

    function makeDerivative(
        uint256 tokenId, 
        string calldata tokenURI, 
        IERC20[] calldata underlyingAssets, 
        uint256[] calldata amounts, 
        string calldata details
    ) external {
        require(underlyingAssets.length == amounts.length, "NO_ARRAY_PARITY");
        
        _mint(msg.sender, tokenId, tokenURI);
        
        derivatives[tokenId] = Derivative({
            underlyingAssets: underlyingAssets,
            amounts: amounts,
            details: details
        });

        for (uint256 i; i < underlyingAssets.length; i++) {
            underlyingAssets[i].transferFrom(msg.sender, address(this), amounts[i]);
        }
    }

    function withdraw(uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _burn(tokenId);

        Derivative memory derivative = derivatives[tokenId];

        for (uint256 i; i < derivative.underlyingAssets.length; i++) {
            derivative.underlyingAssets[i].transfer(msg.sender, derivative.amounts[i]);
        }
        
        delete derivatives[tokenId];
    }
}
