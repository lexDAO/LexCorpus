/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Contract with 'multi-call' batch function, courtesy of @boringcrypto (https://github.com/boringcrypto/BoringSolidity).
contract BatchCall {
    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function batchCall(bytes[] calldata calls, bool revertOnFail) external returns (string memory revertMsg) {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) 
                if (result.length < 68) revertMsg = 'silent';
                    assembly {result := add(result, 0x04)}
                    revertMsg = abi.decode(result, (string)); 
        }
    }
}
