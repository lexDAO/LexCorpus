// SPDX-License-Identifier: GPL3
pragma solidity >=0.8.0;

contract SelfRegulatoryOrganization {
  mapping(address => uint256) public health;
  mapping(address => uint256) public lastActionTimestamp;
  
  string public mandate;
  
  modifier cooldown() {
        require(block.timestamp - lastActionTimestamp[msg.sender] > 1 days);
        _;
        lastActionTimestamp[msg.sender] = block.timestamp;
  }

  function spawn() payable public {
      require(msg.value == 0.1 ether);
      health[msg.sender] = 10;
      
      (bool success, ) = address(0).call{value: address(this).balance}("");
      require(success, "!payable");
  }

  function isAlive(address x) public view returns (bool) {
      return health[x] > 0;
  }

  function hit(address victim) cooldown public {
      require(isAlive(msg.sender));
      health[victim] = health[victim] - 1; 
  }

  function heal(address friend) cooldown public {
      require(isAlive(msg.sender));
      require(health[friend] < 10);
      unchecked {health[friend] = health[friend] + 1;} 
      lastActionTimestamp[msg.sender] = block.timestamp;
  }
}
