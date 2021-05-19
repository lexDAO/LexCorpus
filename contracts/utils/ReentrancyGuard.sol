/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Contract with modifier for reentrancy guard.
contract ReentrancyGuard {
    uint constant _NOT_ENTERED = 1;
    uint constant _ENTERED = 2;
    uint _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, 'ReentrancyGuard:reentrant');
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
