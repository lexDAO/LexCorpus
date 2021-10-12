// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Single owner function access control module.
abstract contract LexOwnable {
    event TransferOwner(address indexed from, address indexed to);
    event TransferOwnerClaim(address indexed from, address indexed to);
    
    address public owner;
    address public pendingOwner;

    /// @notice Initialize ownership module for function access control.
    /// @param _owner Account to grant ownership.
    constructor(address _owner) {
        owner = _owner;
        emit TransferOwner(address(0), _owner);
    }

    /// @notice Access control modifier that conditions function to be restricted to `owner` account.
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /// @notice `pendingOwner` can claim `owner` account.
    function claimOwner() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        emit TransferOwner(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /// @notice Transfer `owner` account.
    /// @param to Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address to, bool direct) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        
        if (direct) {
            owner = to;
            emit TransferOwner(msg.sender, to);
        } else {
            pendingOwner = to;
            emit TransferOwnerClaim(msg.sender, to);
        }
    }
}
