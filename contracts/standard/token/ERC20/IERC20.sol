/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title IERC20
/// @notice Standard ERC20 token interface + EIP-2612 `permit()` extension
interface IERC20 { 
    /// @dev ERC-20
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    /// @dev EIP-2612
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}
