pragma solidity 0.8.0;

contract TimeRestricted {
    uint256 public timeRestriction;

    constructor(uint256 _timeRestriction) {
        timeRestriction = _timeRestriction;
    }
    
    modifier timeRestricted { // requires modified function to be called *at* timeRestriction or after
        require(block.timestamp >= timeRestriction, "!time");
        _;
    }
}
