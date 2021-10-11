// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Contract module that helps prevent reentrant calls to a function.
abstract contract Multicall {
    /// @notice Enables calling multiple methods in a single call to this contract.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);
                if (!success) {
                    if (result.length < 68) revert();
                    assembly { 
                        result := add(result, 0x04) 
                    }
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}
