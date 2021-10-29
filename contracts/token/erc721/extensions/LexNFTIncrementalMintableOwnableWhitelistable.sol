// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../LexNFT.sol';
import '../../../conditions/LexOwnable.sol';
import '../../../conditions/LexWhiteListableMerkleRoot.sol';

/// @notice Extension for LexNFT that allows owner-restricted (incremental) minting and burning, and whitelisting via Merkle root.
contract LexNFTIncrementalMintableOwnable is LexNFT, LexWhiteListableMerkle {
    /// @notice Initialize LexNFT extension.
    /// @param _name Public name for LexNFT.
    /// @param _symbol Public symbol for LexNFT.
    /// @param _owner Account to grant minting ownership.
    constructor(string memory _name, string memory _symbol, address _owner, bool _whitelistEnabled)
        LexNFT(_name, _symbol) LexWhiteListableMerkle(_whitelistEnabled, _owner) {}

    /// @notice Mints a new `tokenId` for `to` incremented from `totalSupply`.
    /// @param to Account that receives mint.
    /// @param _tokenURI MetaData to attach to mint.
    function mint(address to, string memory _tokenURI) external onlyOwner {
        // This is reasonably safe from overflow because incrementing `totalSupply` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            _mint(to, totalSupply + 1, _tokenURI);
        }
    }
}
