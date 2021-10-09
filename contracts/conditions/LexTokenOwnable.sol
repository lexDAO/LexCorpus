// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "./LexOwnable.sol";

/// @notice Access control contract based on ERC20/721 balances.
abstract contract LexTokenOwnable is LexOwnable {
    event SetOwnerTokenBalance(IERC20 indexed token, uint256 indexed ownerBalance);
    
    IERC20 public token; 
    uint256 public ownerBalance; 

    /// @notice Initialize contract with `token` and `ownerBalance` variables.
    constructor(IERC20 _token, uint256 _ownerBalance) {
        token = _token;
        ownerBalance = _ownerBalance;
        emit SetOwnerTokenBalance(_token, _ownerBalance);
    }
    
    /// @notice Access control modifier that conditions modified function to be called by account with `ownerbalance` of `token`.
    modifier onlyTokenOwner {
        require(token.balanceOf(msg.sender) >= ownerBalance, "NOT_OWNER");
        _;
    } 

    /// @notice Returns whether `account` has access control based on `token` `ownerBalance`.
    function checkOwner(address account) external view returns (bool owner) {
        owner = token.balanceOf(account) >= ownerBalance;
    }

    /// @notice Sets `token` and `ownerBalance` for access control.
    function setOwnerTokenBalance(IERC20 _token, uint256 _ownerBalance) external onlyOwner {
        token = _token;
        ownerBalance = _ownerBalance;
        emit SetOwnerTokenBalance(_token, _ownerBalance);
    }
}
