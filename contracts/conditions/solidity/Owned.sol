/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Owned {
    address public owner; 
    
    /// @dev deploy Owned contract - `onlyOwner` modifier enforces condition
    /// @param _owner account with `onlyOwner` permission 
    constructor(address _owner) {
        owner = _owner;
    }
    
    /// @dev requires modified function to be called by `owner`
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
    
    /// @dev update `owner` account
    /// @param _owner account with `onlyOwner` permission 
    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
}
