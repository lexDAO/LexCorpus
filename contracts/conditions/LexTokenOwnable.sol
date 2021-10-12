// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "./LexOwnable.sol";

/// @notice ERC-20/721 balance-based function access control module.
abstract contract LexTokenOwnable is LexOwnable {
    event UpdateOwnerTokenBalance(IERC20 indexed token, uint256 indexed ownerBalance);
    
    IERC20 public token; 
    uint256 public ownerBalance; 

    /// @notice Initialize token ownership module for function access control.
    /// @param _token ERC-20/721 token to use for ownership checks.
    /// @param _ownerBalance Token balance required for ownership access.
    /// @param _owner Account to grant ownership of this module.
    constructor(IERC20 _token, uint256 _ownerBalance, address _owner) LexOwnable(_owner) {
        token = _token;
        ownerBalance = _ownerBalance;
        emit UpdateOwnerTokenBalance(_token, _ownerBalance);
    }
    
    /// @notice Access control modifier that conditions function to be restricted to account with `ownerbalance` of `token`.
    modifier onlyTokenOwner {
        require(token.balanceOf(msg.sender) >= ownerBalance, "NOT_OWNER");
        _;
    } 

    /// @notice Returns whether `account` has ownership access based on their `token` `ownerBalance`.
    /// @param account Address to check.
    function checkTokenOwner(address account) external view returns (bool owner) {
        owner = token.balanceOf(account) >= ownerBalance;
    }

    /// @notice Update `token` and `ownerBalance` for access control.
    /// @param _token ERC-20/721 token to use for ownership checks.
    /// @param _ownerBalance Token balance required for ownership access.
    function updateOwnerTokenBalance(IERC20 _token, uint256 _ownerBalance) external onlyOwner {
        token = _token;
        ownerBalance = _ownerBalance;
        emit UpdateOwnerTokenBalance(_token, _ownerBalance);
    }
}
