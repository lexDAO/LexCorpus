// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "./LexOwnable.sol";

/// @notice Access control contract based on ERC20 balances.
abstract contract LexOwnableERC20 is LexOwnable {
    event SetERC20ownerBalance(IERC20 indexed erc20, uint256 indexed ownerBalance);
    
    IERC20 public erc20; 
    uint256 public ownerBalance; 

    /// @notice Initialize contract with `erc20` and `ownerBalance` variables.
    constructor(IERC20 _erc20, uint256 _ownerBalance) {
        erc20 = _erc20;
        ownerBalance = _ownerBalance;
        emit SetERC20ownerBalance(_erc20, _ownerBalance);
    }
    
    /// @notice Access control modifier that conditions modified function to be called by account with `ownerbalance` of `erc20`.
    modifier onlyERC20Owner {
        require(erc20.balanceOf(msg.sender) >= ownerBalance, "NOT_OWNER");
        _;
    } 

    /// @notice Returns whether `account` has access control based on `erc20` `ownerBalance`.
    function checkOwner(address account) external view returns (bool owner) {
        owner = erc20.balanceOf(account) >= ownerBalance;
    }

    /// @notice Sets `erc20` and `ownerBalance` for access control.
    function setERC20ownerBalance(IERC20 _erc20, uint256 _ownerBalance) external onlyOwner {
        erc20 = _erc20;
        ownerBalance = _ownerBalance;
        emit SetERC20ownerBalance(_erc20, _ownerBalance);
    }
}
