// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../../../LexNFT.sol';
import '../../../LexOwnable.sol';

/// @notice Extension for LexNFT that allows owner-restricted (incremental) minting and burning.

contract LexNFTIncrementalMintableOwnable is LexNFT, LexOwnable {

    constructor(string memory _name, string memory _symbol, uint tokenId, string memory _tokenURI, address owner) LexNFT(_name, _symbol, tokenId, _tokenURI, owner) {}

    function mint(address to, string memory _tokenURI) external onlyOwner {
        _mint(to, totalSupply + 1, _tokenURI);
    }

    function burn(uint tokenId) public onlyOwner {
        _burn(tokenId);
    }

}
