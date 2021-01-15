pragma solidity 0.8.0;

contract Whitelist {
    mapping(address => bool) public whitelist;
    
    function addToWhitelist(address account) external {
        whitelist[account] = true;
    }
}
