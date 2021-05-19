/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title OwnableERC20
/// @notice Use ERC20 ownership for access control
contract OwnableERC20 {
    address private erc20; // access control token address
    uint256 private ownerBalance; // access control token balance
    
    event SetERC20ownerBalance(address indexed erc20, uint256 ownerBalance);
    
    /// @dev initialize contract with `erc20` and `ownerBalance` variables
    constructor(address _erc20, uint256 _ownerBalance) {
        erc20 = _erc20;
        ownerBalance = _ownerBalance;
        emit SetERC20ownerBalance(_erc20, _ownerBalance);
    }
    
    /// @dev access control modifier that requires modified function to be called by account with `ownerbalance` of `erc20`
    modifier onlyOwner {
        require(IERC20(erc20).balanceOf(msg.sender) >= ownerBalance, "!owner");
        _;
    } 
    
    /// @dev return `erc20` and `ownerBalance` for access control
    function erc20OwnerBalance() public view virtual returns (address, uint256) {
        return (erc20, ownerBalance);
    }
    
    /// @dev return whether `account` has access control
    function checkOwner(address account) public view virtual returns (bool) {
        return IERC20(erc20).balanceOf(account) >= ownerBalance;
    }
    
    /// @dev return whether caller has access control
    function isOwner() public view virtual returns (bool) {
        return IERC20(erc20).balanceOf(msg.sender) >= ownerBalance;
    }
    
    /// @dev internal function to set `erc20` and `ownerbalance` for access control 
    function _setERC20ownerBalance(address _erc20, uint256 _ownerBalance) internal {
        erc20 = _erc20;
        ownerBalance = _ownerBalance;
        emit SetERC20ownerBalance(_erc20, _ownerBalance);
    }
}
