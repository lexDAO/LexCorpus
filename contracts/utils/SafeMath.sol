// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0;

/// @notice A library for performing over/underflow-safe math.
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "OVERFLOW");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "UNDERFLOW");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "OVERFLOW");
    }
}
