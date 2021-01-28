// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Whitelist {
    address public owner;
    mapping(address => bool) public whitelist;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
    
    modifier onlyWhitelist {
        require(whitelist[msg.sender]);
        _;
    }
    
    function addToWhitelist(address account) onlyOwner external {
        whitelist[account] = true;
    }
    
    function changeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }
}
