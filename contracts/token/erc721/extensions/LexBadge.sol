// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../LexNFT.sol';
import '../../../conditions/LexOwnable.sol';

/// @notice Extension for LexNFT that allows owner-restricted minting and burning of non-transferable NFTs.
contract LexBadge is LexNFT, LexOwnable {
    /// @notice Initialize LexNFT extension.
    /// @param _name Public name for LexNFT.
    /// @param _symbol Public symbol for LexNFT.
    /// @param _owner Account to grant minting ownership.
    constructor(string memory _name, string memory _symbol, address _owner) LexNFT(_name, _symbol) LexOwnable(_owner) {}

    /// @notice Disables transferability by overriding transfer functions of LexNFT.
    function transfer(address, uint256) public pure override {
        revert();
    }

    function transferFrom(address, address, uint256) public pure override {
        revert();
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override {
        revert();
    }

    /// @notice Mints a new token at `tokenId` for `to`.
    /// @param to Account that receives mint.
    /// @param _tokenURI MetaData to attach to mint.
    function mint(address to, uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _mint(to, tokenId, _tokenURI);
    }

    /// @notice Burns token at `tokenId`.
    function burn(uint tokenId) external onlyOwner {
        _burn(tokenId);
    }

}
