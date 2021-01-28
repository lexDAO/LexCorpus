/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract TimeRestricted {
    uint256 immutable public timeRestrictionLift; 
    
    /// @dev deploy TimeRestricted contract - `timeRestricted` modifier enforces condition
    /// @param _timeRestrictionLift unix time for condition to lift
    constructor(uint256 _timeRestrictionLift) {
        timeRestrictionLift = _timeRestrictionLift;  
    }
    
    /// requires modified function to be called *at* `timeRestrictionLift` in unix time or after
    modifier timeRestricted { 
        require(block.timestamp >= timeRestrictionLift, "!time");
        _;
    }
}
