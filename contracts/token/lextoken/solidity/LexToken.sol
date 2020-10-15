/**
██╗     ███████╗██╗  ██╗                    
██║     ██╔════╝╚██╗██╔╝                    
██║     █████╗   ╚███╔╝                     
██║     ██╔══╝   ██╔██╗                     
███████╗███████╗██╔╝ ██╗                    
╚══════╝╚══════╝╚═╝  ╚═╝                    
████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
   ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
   ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
   ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
DEAR MSG.SENDER(S):
/ LexToken is a project in beta.
// Please audit and use at your own risk.
/// Entry into LexToken shall not create an attorney/client relationship.
//// Likewise, LexToken should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W 
////// presented by LexDAO LLC
**/
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
}

contract LexToken {
    using SafeMath for uint256;
    address payable public manager; // account managing token rules & sale - see 'Manager Functions' - updateable by manager
    address public resolver; // account acting as backup for lost token & arbitration of disputed token transfers - updateable by manager
    uint8 public decimals; // declares fixed unit scaling factor - default 18 to match ETH
    uint256 public saleRate; // rate of token purchase when sending ETH to contract - e.g., 10 saleRate returns 10 token per 1 ETH - updateable by manager
    uint256 public totalSupply; // tracks outstanding token mints
    uint256 public totalSupplyCap; // maximum of token mintable
    bytes32 public DOMAIN_SEPARATOR; // eip-2612 permit() pattern - hash that uniquely identifies contract
    bytes32 public PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"); // eip-2612 permit() pattern - identifies function for signature
    string public details; // describe rules of token offering, redemption, etc. - updateable by manager
    string public name; // declares fixed name of token
    string public symbol; // declares fixed symbol of token
    bool public forSale; // declares status of token sale - if `false`, ETH sent to token address will not return token per saleRate - updateable by manager
    bool private initialized; // finalizes token deployment under eip-1167 proxy pattern
    bool public transferable; // declares transferability of token - does not affect token sale - updateable by manager
    
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event BalanceResolution(string indexed resolution);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) public balanceOf;
    mapping (address => uint256) public nonces;
    
    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }
    
    function init(
        address payable _manager,
        address _resolver,
        uint8 _decimals, 
        uint256 managerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap,
        string calldata _details, 
        string calldata _name, 
        string calldata _symbol,  
        bool _forSale, 
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 
        require(managerSupply.add(saleSupply) <= _totalSupplyCap, "capped");
        manager = _manager; 
        resolver = _resolver;
        decimals = _decimals; 
        saleRate = _saleRate; 
        totalSupplyCap = _totalSupplyCap; 
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        forSale = _forSale; 
        initialized = true; 
        transferable = _transferable; 
        balanceOf[manager] = managerSupply;
        balanceOf[address(this)] = saleSupply;
        totalSupply = managerSupply.add(saleSupply);
        // eip-2612 permit() pattern:
        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes("1")),
            chainId,
            address(this)));
        emit Transfer(address(0), manager, managerSupply);
        emit Transfer(address(0), address(this), saleSupply);
    }
    
    receive() external payable { // SALE 
        require(forSale, "!forSale");
        (bool success, ) = manager.call{value: msg.value}("");
        require(success, "!transfer");
        uint256 amount = msg.value.mul(saleRate); 
        _transfer(address(this), msg.sender, amount);
    } 
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(amount == 0 || allowances[owner][spender] == 0, "!reset"); 
        allowances[owner][spender] = amount; 
        emit Approval(owner, spender, amount); 
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function balanceResolution(address from, address to, uint256 amount, string calldata resolution) external { // resolve disputed or lost balances
        require(msg.sender == resolver, "!resolver"); 
        _transfer(from, to, amount); 
        emit BalanceResolution(resolution);
    }
    
    function burn(uint256 amount) external {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount); 
        totalSupply = totalSupply.sub(amount); 
        emit Transfer(msg.sender, address(0), amount);
    }
    
    // Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "expired");
        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "!signer");
        _approve(owner, spender, value);
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] = balanceOf[from].sub(amount); 
        balanceOf[to] = balanceOf[to].add(amount); 
        emit Transfer(from, to, amount); 
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(transferable, "!transferable"); 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount); 
        balanceOf[to] = balanceOf[to].add(amount); 
        emit Transfer(msg.sender, to, amount); 
        return true;
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata amount) external {
        require(to.length == amount.length, "!to/amount");
        require(transferable, "!transferable");
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], amount[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(transferable, "!transferable");
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(amount); 
        _transfer(from, to, amount);
        return true;
    }
    
    /****************
    MANAGER FUNCTIONS
    ****************/
    function _mint(address to, uint256 amount) internal {
        require(totalSupply.add(amount) <= totalSupplyCap, "capped"); 
        balanceOf[to] = balanceOf[to].add(amount); 
        totalSupply = totalSupply.add(amount); 
        emit Transfer(address(0), to, amount); 
    }
    
    function mint(address to, uint256 amount) external onlyManager {
        _mint(to, amount);
    }
    
    function mintBatch(address[] calldata to, uint256[] calldata amount) external onlyManager {
        require(to.length == amount.length, "!to/amount");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], amount[i]); 
        }
    }
    
    function updateGovernance(address payable _manager, address _resolver, string calldata _details) external onlyManager {
        manager = _manager;
        resolver = _resolver;
        details = _details;
    }

    function updateSale(uint256 amount, uint256 _saleRate, bool _forSale) external onlyManager {
        saleRate = _saleRate;
        forSale = _forSale;
        _mint(address(this), amount);
    }
    
    function updateTransferability(bool _transferable) external onlyManager {
        transferable = _transferable;
    }
}

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract CloneFactory {
    function createClone(address payable target) internal returns (address payable result) { // adapted for payable lexToken
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract LexTokenFactory is CloneFactory {
    address payable public lexDAO;
    address payable public template;
    string public details;
    
    event LaunchLexToken(address indexed lexToken, address indexed owner, address indexed resolver, bool forSale);
    event UpdateGovernance(address indexed lexDAO, string indexed details);
    
    constructor(address payable _lexDAO, address payable _template, string memory _details) {
        lexDAO = _lexDAO;
        template = _template;
        details = _details;
    }
    
    function launchLexToken(
        address payable _manager,
        address _resolver,
        uint8 _decimals, 
        uint256 managerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap,
        string memory _details,
        string memory _name, 
        string memory _symbol, 
        bool _forSale, 
        bool _transferable
    ) payable public {
        LexToken lex = LexToken(createClone(template));
        
        lex.init(
            _manager,
            _resolver,
            _decimals, 
            managerSupply, 
            _saleRate, 
            saleSupply, 
            _totalSupplyCap,
            _details,
            _name, 
            _symbol, 
            _forSale, 
            _transferable);
        
        (bool success, ) = lexDAO.call{value: msg.value}("");
        require(success, "!transfer");
        emit LaunchLexToken(address(lex), _manager, _resolver, _forSale);
    }
    
    function updateGovernance(address payable _lexDAO, string calldata _details) external {
        require(msg.sender == lexDAO, "!lexDAO");
        lexDAO = _lexDAO;
        details = _details;
        emit UpdateGovernance(lexDAO, details);
    }
}
