// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0; 

library Address { // helper for address type
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
