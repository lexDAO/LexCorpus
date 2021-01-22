pragma solidity 0.8.0;

contract WhitelistEnabled {
    address public owner;
    bool public WhitelistEnabled;
    mapping(address => bool) public whitelist;
    
    constructor() {
        owner = msg.sender;
        WhitelistEnabled = true;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
    
    modifier onlyWhitelist {
        if (WhitelistEnabled) {
            require(whitelist[msg.sender]);
            _;
        }
    }
    
    function addToWhitelist(address account) onlyOwner external {
        whitelist[account] = true;
    }
    
    function changeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }
    
    function toggleWhitelist(bool enabled) onlyOwner external {
        WhitelistEnabled = enabled;
    }
}
