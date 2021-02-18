/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner; // `owner` account with access control
    address private _pendingOwner; // `pendingOwner` that can call `claimOwner()` for access control
    
    event TransferOwnership(address indexed from, address indexed to); // track `owner` transfers
    event TransferOwnershipClaim(address indexed from, address indexed to); // track transfer of `owner` claim to `pendingOwner`
    
    /// @dev initialize contract
    /// @param _owner Account granted access control
    constructor(address owner) {
        _owner = owner;
        emit TransferOwnership(address(0), owner);
    }
    
    /// @dev access control modifier that requires modified function to be called by `owner` account
    modifier onlyOwner {
        require(msg.sender == _owner, "!owner);
        _;
    } 
    
    /// @dev return `owner` account with access control
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    /// @dev return whether caller has access control
    function isOwner() public view virtual returns (bool) {
        if (msg.sender == _owner) {
            return true;
        }
    }
    
    /// @dev return `pendingOwner` account with access control claim
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }
    
    /// @dev return whether caller has access control claim
    function isPendingOwner() public view virtual returns (bool) {
        if (msg.sender == _pendingOwner) {
            return true;
        }
    }
    
    /// @dev `pendingOwner` can claim `owner` account
    function claimOwner() external {
        require(msg.sender == _pendingOwner, "!pendingOwner");
        emit TransferOwnership(_owner, msg.sender);
        _owner = msg.sender;
        _pendingOwner = address(0);
    }
    
    /// @dev transfer `owner` account
    /// @param to Account granted `owner` access control
    function transferOwnership(address to, bool direct) external onlyOwner {
        if (direct) {
            _owner = to;
            emit TransferOwnership(msg.sender, to);
        } else {
            _pendingOwner = to;
            emit TransferOwnershipClaim(msg.sender, to);
        }
    }
}
