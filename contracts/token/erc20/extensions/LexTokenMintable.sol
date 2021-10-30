// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../../LexToken.sol';
import '../../../LexOwnable.sol';

/// @notice LexToken with owned minting.
contract LexTokenMintable is LexToken, LexOwnable {
    /// @notice Initialize LexToken extension.
    /// @param _name Public name for LexToken.
    /// @param _symbol Public symbol for LexToken.
    /// @param _decimals Unit scaling factor - default '18' to match ETH units. 
    /// @param _owner Account to grant minting ownership.
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner) LexToken(_name, _symbol, _decimals) LexOwnable(_owner) {}
    
    /// @notice Mints tokens by `owner`.
    /// @param to Account to receive tokens.
    /// @param amount Sum to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
