/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Whitelistable is Ownable {
    bool private _whitelistEnabled; // track access control status
    mapping(address => bool) private _whitelisted; // track account whitelisting
    
    /// @dev initialize contract with `owner` variable and `whitelistEnabled` status
    constructor(address owner, bool whitelistEnabled) Ownable(owner) {}
    
    /// @dev requires modified function to be called by `whitelisted` account
    modifier onlyWhitelisted {
        require(_whitelisted[msg.sender], "!whitelisted");
        _;
    }
    
    /// @dev return whether `whitelistEnabled` for access control
    function whitelistEnabled() public view virtual returns (bool) {
        return _whitelistEnabled;
    }
    
    /// @dev return whether `account` is `whitelisted` for access control
    function whitelisted(address account) public view virtual returns (bool) {
        return _whitelisted[account];
    }
    
    /// @dev update account `whitelisted` status
    /// @param account Account to update 
    /// @param whitelisted If `true`, `account` is `whitelisted` for access control
    function updateWhitelist(address account, bool whitelisted) onlyOwner external {
        _whitelisted[account] = whitelisted;
    }
    
    /// @dev `owner` can toggle `whitelisted` access control on/off
    /// @param whitelistEnabled If `true`, `whitelisted` access control is on
    function toggleWhitelist(bool whitelistEnabled) onlyOwner external {
        _whitelistEnabled = whitelistEnabled;
    }
}
