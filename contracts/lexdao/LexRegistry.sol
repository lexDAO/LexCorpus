// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

contract LexRegistry {
    
    address public owner;
    
    mapping(address => Lawyer) public lawyers;
    
    struct Lawyer {
        string name;
        string jurisdiction;
        string details;
        bool availability;
    }
    
    constructor()  {
        owner = msg.sender;
    }
    
    function register(address lawyer, string calldata name, string calldata jurisdiction, string calldata details) external {
        require(msg.sender == owner, "NOT_OWNER");
        lawyers[owner] = Lawyer(name, jurisdiction, details, true);
    
    }
    
    function updateAvailability(bool availability) external {
        bytes memory name = bytes(lawyers[msg.sender].name);
        require(name.length > 0, "NOT_LAWYER");
        lawyers[msg.sender].availability = availability;
    }

    function transferOwner(address _owner) external {
        require(msg.sender == owner, "NOT_OWNER");
        owner = _owner;
    }
}


