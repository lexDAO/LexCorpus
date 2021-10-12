// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../../../LexNFT.sol';
import '../../../LexOwnable.sol';

/// @notice Extension for LexNFT that allows owner-restricted (incremental) minting and burning.
contract LexNFTIncrementalMintableOwnable is LexNFT, LexOwnable {
    constructor(string memory _name, string memory _symbol, address _owner) 
        LexNFT(_name, _symbol) LexOwnable(_owner) {}
    
    /// @notice Mints a new `tokenId` for `to` incremented from `totalSupply`.
    /// @param to Account that receives mint.
    /// @param _tokenURI MetaData to attach to mint.
    function mint(address to, string memory _tokenURI) public onlyOwner {
        _mint(to, totalSupply + 1, _tokenURI);
    }
}
