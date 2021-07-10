/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

/// @notice This contract manages function access control, adapted from @boringcrypto (https://github.com/boringcrypto/BoringSolidity).
contract Ownable {
    address public owner; 
    address public pendingOwner;
    
    event TransferOwnership(address indexed from, address indexed to); 
    event TransferOwnershipClaim(address indexed from, address indexed to);
    
    /// @notice Initialize contract.
    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }
    
    /// @notice Access control modifier that requires modified function to be called by `owner` account.
    modifier onlyOwner {
        require(msg.sender == owner, 'Ownable:!owner');
        _;
    } 
    
    /// @notice The `pendingOwner` can claim `owner` account.
    function claimOwner() external {
        require(msg.sender == pendingOwner, 'Ownable:!pendingOwner');
        emit TransferOwnership(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }
    
    /// @notice Transfer `owner` account.
    /// @param to Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred. 
    function transferOwnership(address to, bool direct) external onlyOwner {
        if (direct) {
            owner = to;
            emit TransferOwnership(msg.sender, to);
        } else {
            pendingOwner = to;
            emit TransferOwnershipClaim(msg.sender, to);
        }
    }
}
