// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice A simple lawyer registry contract for LexDAO.
contract LexRegistry {
    address public owner;

    mapping(address => Lawyer) public lawyers;

    struct Lawyer {
        string name;
        string jurisdiction;
        string details;
        bool availability;
    }

    constructor() {
        owner = msg.sender;
    }

    function register(address lawyer, string calldata name, string calldata jurisdiction, string calldata details) external {
        require(msg.sender == owner, "NOT_OWNER");
        lawyers[lawyer] = Lawyer(name, jurisdiction, details, true);
    }

    function updateAvailability(bool availability) external {
        bytes memory name = bytes(lawyers[msg.sender].name);
        require(name.length > 0, "NOT_LAWYER");
        lawyers[msg.sender].availability = availability;
    }

    function transferOwner(address owner_) external {
        require(msg.sender == owner, "NOT_OWNER");
        owner = owner_;
    }
}
