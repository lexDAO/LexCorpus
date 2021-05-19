/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice A library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math).
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath:Add-Over');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath:Sub-Over');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath:Mul-Over');
    }
}
