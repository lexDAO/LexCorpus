// SPDX-License-Identifier: GPL-3
pragma solidity >=0.8.0;

contract LexFaucet {
    mapping(address => bool) public claimed;
    
    function claimETH() external {
        require(!claimed[msg.sender], "claimed");
        (bool success, ) = msg.sender.call{value: 1 ether / 1000}(""); 
        require(success, "!payable");
        claimed[msg.sender] = true; // maps claim to caller to avoid repeat
    }
    
    receive() external payable {} 
}
