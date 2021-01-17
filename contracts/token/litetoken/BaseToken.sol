pragma solidity 0.8.0;

contract BaseToken {
    string public name = "TOKEN";
    string public symbol = "TKN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 ether;
    
    constructor() {balanceOf[msg.sender] = totalSupply;}
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    function approve(address to, uint256 amount) external returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        balanceOf[to] = balanceOf[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balanceOf[from] = balanceOf[from] - amount;
        balanceOf[to] = balanceOf[to] + amount;
        allowance[from][msg.sender] = allowance[from][msg.sender] - amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
