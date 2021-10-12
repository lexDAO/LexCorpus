// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./LexOwnable.sol";

/// @notice Ownable function time restriction module.
abstract contract LexTimeRestricted is LexOwnable {
    event ToggleTimeRestriction(bool indexed timeRestrictionEnabled);
    event UpdateTimeRestriction(uint256 indexed timeRestriction);
    
    uint256 public timeRestriction; 
    bool public timeRestrictionEnabled;
    
    /// @notice Initialize time restriction module.
    /// @param _timeRestriction Point when restriction ends in Unix time.
    /// @param _timeRestrictionEnabled If 'true', modified functions are restricted.
    constructor(uint256 _timeRestriction, bool _timeRestrictionEnabled) {
        timeRestriction = _timeRestriction;
        timeRestrictionEnabled = _timeRestrictionEnabled;
        emit ToggleTimeRestriction(_timeRestrictionEnabled);
    }
    
    /// @notice Time restriction modifier that conditions function to be called at `timeRestriction` or after.
    modifier timeRestricted { 
        if (timeRestrictionEnabled)
        require(block.timestamp >= timeRestriction, "TIME_RESTRICTED");
        _;
    }
    
    /// @notice Toggle `timeRestriction` conditions on/off.
    /// @param _timeRestrictionEnabled If 'true', `timeRestriction` conditions are on.
    function toggleTimeRestriction(bool _timeRestrictionEnabled) external onlyOwner {
        timeRestrictionEnabled = _timeRestrictionEnabled;
        emit ToggleTimeRestriction(_timeRestrictionEnabled);
    }
    
    /// @notice Update `timeRestriction` in Unix time.
    /// @param _timeRestriction Point when restriction ends in Unix time.
    function updateTimeRestriction(uint256 _timeRestriction) external onlyOwner {
        timeRestriction = _timeRestriction;
        emit UpdateTimeRestriction(_timeRestriction);
    }
}
