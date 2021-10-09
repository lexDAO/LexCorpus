// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Access control contract.
/// @author Adapted from https://github.com/sushiswap/trident/blob/master/contracts/utils/TridentOwnable.sol.
abstract contract LexOwnable {
    event TransferOwner(address indexed sender, address indexed recipient);
    event TransferOwnerClaim(address indexed sender, address indexed recipient);
    
    address public owner;
    address public pendingOwner;

    /// @notice Initialize and grant deployer account (`msg.sender`) `owner` access role.
    constructor() {
        owner = msg.sender;
        emit TransferOwner(address(0), msg.sender);
    }

    /// @notice Access control modifier that conditions modified function to be called by `owner` account.
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
    /// @param recipient Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address recipient, bool direct) external onlyOwner {
        require(recipient != address(0), "ZERO_ADDRESS");
        if (direct) {
            owner = recipient;
            emit TransferOwner(msg.sender, recipient);
        } else {
            pendingOwner = recipient;
            emit TransferOwnerClaim(msg.sender, recipient);
        }
    }
}
