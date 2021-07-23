/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice This contract manages function access control, adapted from @boringcrypto (https://github.com/boringcrypto/BoringSolidity).
contract Ownable {
    address public owner; 
    address public pendingOwner;
    
    event TransferOwnership(address indexed from, address indexed to); 
    event TransferOwnershipClaim(address indexed from, address indexed to);
    
    /// @notice Initialize contract.
    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }
    
    /// @notice Access control modifier that requires modified function to be called by `owner` account.
    modifier onlyOwner {
        require(msg.sender == owner, 'Ownable:!owner');
        _;
    } 
    
    /// @notice The `pendingOwner` can claim `owner` account.
    function claimOwner() external {
        require(msg.sender == pendingOwner, 'Ownable:!pendingOwner');
        emit TransferOwnership(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }
    
    /// @notice Transfer `owner` account.
    /// @param to Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred. 
    function transferOwnership(address to, bool direct) external onlyOwner {
        if (direct) {
            owner = to;
            emit TransferOwnership(msg.sender, to);
        } else {
            pendingOwner = to;
            emit TransferOwnershipClaim(msg.sender, to);
        }
    }
}

contract TimeRestricted {
    uint immutable public timeRestrictionEnds; 
    
    /// @notice deploy `TimeRestricted` contract.
    /// @param _timeRestrictionEnds Unix time for restriction to lift.
    constructor(uint _timeRestrictionEnds) {
        timeRestrictionEnds = _timeRestrictionEnds;  
    }
    
    /// @notice Requires modified function to be called *at* `timeRestrictionEnds` in unix time or after.
    modifier timeRestricted { 
        require(block.timestamp >= timeRestrictionEnds, 'TimeRestricted:!time');
        _;
    }
}

/// @notice Basic ERC20 implementation with ownership and time restriction.
contract TimeRestrictedOwnableToken is Ownable, TimeRestricted {
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    constructor(
        address owner, 
        string memory _name, 
        string memory _symbol, 
        uint _totalSupply,
        uint _timeRestrictionEnds) TimeRestricted(_timeRestrictionEnds) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function approve(address to, uint amount) external returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function transfer(address to, uint amount) external onlyOwner timeRestricted returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) external onlyOwner timeRestricted returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) 
            allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
