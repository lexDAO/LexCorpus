// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./LexOwnable.sol";

/// @notice Function pausing contract.
abstract contract LexPausable is LexOwnable {
    event SetPause(bool indexed paused);
    
    bool public paused;
    
    /// @notice Initialize contract with `paused` status.
    constructor(bool _paused) {
        paused = _paused;
        emit SetPause(_paused);
    }
    
    /// @notice Function pausability modifier.
    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }
    
    /// @notice Sets function pausing status.
    /// @param _paused If 'true', modified functions are paused.
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
        emit SetPause(_paused);
    }
}
