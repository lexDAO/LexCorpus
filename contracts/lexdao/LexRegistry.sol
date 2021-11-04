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
    
    event LawyerRegistered(address indexed lawyer, string name, string jurisdiction, string details);
    event UpdatedAvailability(address indexed lawyer, bool availability);

    constructor() {
        owner = msg.sender;
    }
    
    // @param lawyer: ETH address of lawyer to be registered
    // @param name: name of lawyer
    // @param jurisdiction: jurisdiction(s) in which lawyer is qualified to practice 
    // @param details: lawyer's link, bio, or concise explanation of lawyer's expertise or experience
    function register(address lawyer, string calldata name, string calldata jurisdiction, string calldata details) external {
        require(msg.sender == owner, "NOT_OWNER");
        lawyers[lawyer] = Lawyer(name, jurisdiction, details, true);
        emit LawyerRegistered(lawyer, name, jurisdiction, details);
    }

    function updateAvailability(bool availability) external {
        bytes memory name = bytes(lawyers[msg.sender].name);
        require(name.length > 0, "NOT_LAWYER");
        lawyers[msg.sender].availability = availability;
        emit UpdatedAvailability(msg.sender, availability);
    }

    function transferOwner(address owner_) external {
        require(msg.sender == owner, "NOT_OWNER");
        owner = owner_;
    }
}
