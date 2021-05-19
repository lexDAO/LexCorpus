/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract TimeRestricted {
    uint256 immutable public timeRestrictionEnds; 
    
    /// @notice deploy `TimeRestricted` contract
    /// @param _timeRestrictionEnds unix time for restriction to lift
    constructor(uint256 _timeRestrictionEnds) {
        timeRestrictionEnds = _timeRestrictionEnds;  
    }
    
    /// @notice requires modified function to be called *at* `timeRestrictionEnds` in unix time or after
    modifier timeRestricted { 
        require(block.timestamp >= timeRestrictionEnds, "!time");
        _;
    }
}
