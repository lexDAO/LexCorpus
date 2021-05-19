/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract TimeRestricted {
    uint immutable public timeRestrictionEnds; 
    
    /// @notice deploy `TimeRestricted` contract.
    /// @param _timeRestrictionEnds Unix time for restriction to lift.
    constructor(uint _timeRestrictionEnds) {
        timeRestrictionEnds = _timeRestrictionEnds;  
    }
    
    /// @notice Requires modified function to be called *at* `timeRestrictionEnds` in unix time or after.
    modifier timeRestricted { 
        require(block.timestamp >= timeRestrictionEnds, 'TimeRestricted:!time');
        _;
    }
}
