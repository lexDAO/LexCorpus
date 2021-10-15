// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../../LexToken.sol';
import '../../../LexOwnable.sol';

contract LexTokenMintableOwnable is LexToken, LexOwnable {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner) 
        LexToken(_name, _symbol, _decimals) 
        LexOwnable(_owner) 
    {}
    
    function mint(address to, uint256 value) external onlyOwner {
        _mint(to, value);
    }
    
    function burn(address from, uint256 value) external onlyOwner {
        _burn(from, value);
    }
}
