/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Contract with 'multi-call' batch function, courtesy of @boringcrypto (https://github.com/boringcrypto/BoringSolidity).
contract BatchCall {
    /// @dev Helper function to extract a useful revert message from a failed call.
    function _getRevertMsg(bytes memory _returnData) private pure returns (string memory revertMsg) {
        // @dev If length is less than 68, the transaction failed silently without a revert message.
        if (_returnData.length < 68) revertMsg = "Transaction reverted silently";
        assembly {
            // @dev Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        // @dev All that remains is the revert string.
        revertMsg = abi.decode(_returnData, (string));
    }
    
    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function batchCall(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) revert(_getRevertMsg(result));
        }
    }
}
