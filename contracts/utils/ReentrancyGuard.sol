// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Contract module that helps prevent reentrant calls to a function.
abstract contract ReentrancyGuard {
    uint256 status = 1;
    
    modifier nonReentrant() {
        require(status == 1, "reentrant"); 
        status = 2; 
        _;
        status = 1;
    }
}
