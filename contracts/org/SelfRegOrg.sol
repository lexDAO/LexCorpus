// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../conditions/IPool.sol";

contract SelfRegOrg is Ownable {
    string public purposeAndRules;
    
    mapping(address => uint256) public reputation;
    mapping(address => uint256) public lastActionTimestamp;
    
    constructor(string memory _purposeAndRules) {
        purposeAndRules = _purposeAndRules;
    }
  
    modifier cooldown() {
        require(block.timestamp - lastActionTimestamp[msg.sender] > 1 days);
        _;
        lastActionTimestamp[msg.sender] = block.timestamp;
    }
    
    function isInGoodStanding(address account) public view returns (bool standing) {
        standing = reputation[account] > 0;
    }

    function join() external payable {
        require(msg.value == 0.1 ether, '!tribute'); // @dev Check ETH required to join SRO is included in call.
        reputation[msg.sender] = 3; // @dev 'Three strikes and you're out' system for member mgmt.
    }

    function report(address account) cooldown external {
        require(isInGoodStanding(msg.sender), '!inGoodStanding');
        reputation[account] -= 1; 
    }

    function support(address account) cooldown external {
        require(isInGoodStanding(msg.sender), '!inGoodStanding');
        require(reputation[account] < 3);
        unchecked {
            reputation[account] += 1;
        } 
    }
    
    function withdrawETH(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "!payable");
    }
}
