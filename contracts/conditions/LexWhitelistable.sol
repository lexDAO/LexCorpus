// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./LexOwnable.sol";

/// @notice Function whitelisting contract.
abstract contract LexWhitelistable is LexOwnable {
    event ToggleWhiteList(bool indexed whitelistEnabled);
    event UpdateWhitelist(address indexed account, bool indexed whitelisted);
    
    bool public whitelistEnabled; 
    
    mapping(address => bool) public whitelisted; 
    
    /// @notice Initialize contract with `whitelistEnabled` status.
    constructor(bool _whitelistEnabled) {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }
    
    /// @notice Whitelisting modifier that conditions modified function to be called between `whitelisted` accounts.
    modifier onlyWhitelisted(address from, address to) {
        if (whitelistEnabled) 
        require(whitelisted[from] && whitelisted[to], "NOT_WHITELISTED");
        _;
    }
    
    /// @notice Toggle `whitelisted` conditions on/off.
    /// @param _whitelistEnabled If 'true', `whitelisted` conditions are on.
    function toggleWhitelist(bool _whitelistEnabled) external onlyOwner {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }
    
    /// @notice Update account `whitelisted` status.
    /// @param account Account to update.
    /// @param _whitelisted If 'true', `account` is `whitelisted`.
    function updateWhitelist(address account, bool _whitelisted) external onlyOwner {
        whitelisted[account] = _whitelisted;
        emit UpdateWhitelist(account, _whitelisted);
    }
}
