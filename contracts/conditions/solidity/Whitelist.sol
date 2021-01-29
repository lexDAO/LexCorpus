/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Whitelisted is Owned {
    mapping(address => bool) public whitelist;
    
    /// @dev deploy Whitelisted contract - `onlyWhitelist` modifier enforces condition
    /// @param _owner account with `onlyOwner` permission in `Owned` contract
    constructor(address _owner) Owned(_owner) {}
    
    /// @dev requires modified function to be called by `whitelist` account
    modifier onlyWhitelist {
        require(whitelist[msg.sender], "!whitelist");
        _;
    }
    
    /// @dev add account to `whitelist`
    /// @param _account account to add `whitelist`
    function addToWhitelist(address account) onlyOwner external {
        whitelist[account] = true;
    }
}
