pragma solidity 0.8.0; // SPDX-License-Identifier: GPL-3.0-or-later
contract LiteToken { // minimal viable erc20 token with common extensions, such as burn, cap, mint, pauseable, admin functions
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    bool public transferable; 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner, uint256 _initialSupply, uint256 _totalSupplyCap, bool _transferable) {require(_initialSupply <= _totalSupplyCap, "capped");
        name = _name; symbol = _symbol; decimals = _decimals; owner = _owner; totalSupply = _initialSupply; totalSupplyCap = _totalSupplyCap; transferable = _transferable; balanceOf[owner] = totalSupply; emit Transfer(address(0), owner, totalSupply);}
    function approve(address spender, uint256 amount) external returns (bool) {require(amount == 0 || allowance[msg.sender][spender] == 0); allowance[msg.sender][spender] = amount; emit Approval(msg.sender, spender, amount); return true;}
    function burn(uint256 amount) external {balanceOf[msg.sender] = balanceOf[msg.sender] - amount; totalSupply = totalSupply - amount; emit Transfer(msg.sender, address(0), amount);}
    function mint(address recipient, uint256 amount) external {require(msg.sender == owner, "!owner"); require(totalSupply + amount <= totalSupplyCap, "capped"); balanceOf[recipient] = balanceOf[recipient] + amount; totalSupply = totalSupply + amount; emit Transfer(address(0), recipient, amount);}
    function transfer(address recipient, uint256 amount) external returns (bool) {require(transferable == true); balanceOf[msg.sender] = balanceOf[msg.sender] - amount; balanceOf[recipient] = balanceOf[recipient] + amount; emit Transfer(msg.sender, recipient, amount); return true;}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {require(transferable == true); balanceOf[sender] = balanceOf[sender] - amount; balanceOf[recipient] = balanceOf[recipient] + amount; allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount; emit Transfer(sender, recipient, amount); return true;}
    function transferOwner(address _owner) external {require(msg.sender == owner, "!owner"); owner = _owner;}
    function updateTransferability(bool _transferable) external {require(msg.sender == owner, "!owner"); transferable = _transferable;}
}
