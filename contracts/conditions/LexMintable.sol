// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

/// @notice This must be layered on top of both LexNFT and LexOwnable. Extends LexNFT to allow multiple mints by owner.

import './LexNFT.sol';
import './LexOwnable.sol';

contract LexMintable is LexOwnable, LexNFT {

    uint counter;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 tokenId,
        string memory _tokenURI,
        address owner
    ) LexNFT(_name, _symbol, tokenId, _tokenURI, owner)
       {
        counter = tokenId + 1;
    }
    function mint(address to, string memory _tokenURI) public onlyOwner {
        _mint(to, counter, _tokenURI);
    }

    function burn(uint tokenId) public onlyOwner {
        _burn(tokenId);
    }

}
