/// Presented by LexDAO LLC
/// SPDX-License-Identifier: GPL-3.0-or-later
/// @notice Batch 'multi-call' based on @boringcrypto/boring-solidity/contracts/BoringBatchable.sol@v1.2.0.
pragma solidity 0.8.4;

contract BatchCall {
    function batchCall(bytes[] calldata calls, bool revertOnFail) external returns (string memory revertMsg) {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) 
                if (result.length < 68) revertMsg = "silent";
                    assembly {result := add(result, 0x04)}
                    revertMsg = abi.decode(result, (string)); 
        }
    }
}
