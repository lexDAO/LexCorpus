/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Whitelisted is Owned {
    mapping(address => bool) public whitelist; // track account status
    
    /// @dev deploy Whitelisted contract - `onlyWhitelist` modifier enforces condition
    /// @param owner Account with `onlyOwner` permission in `Owned` contract
    constructor(address owner) Owned(owner) {}
    
    /// @dev requires modified function to be called by `whitelist` account
    modifier onlyWhitelist {
        require(whitelist[msg.sender], "!whitelist");
        _;
    }
    
    /// @dev update account `whitelist` status
    /// @param account Account to update 
    /// @param whitelisted Status on `whitelist` to update - if `true,` account is active
    function updateWhitelist(address account, bool whitelisted) onlyOwner external {
        whitelist[account] = whitelisted;
    }
}
