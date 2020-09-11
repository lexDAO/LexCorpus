pragma solidity 0.5.17;

contract ReentrancyGuard { 
    bool private _notEntered; 
    
    function _initReentrancyGuard() internal {
        _notEntered = true;
    } 
}

contract LexNFT is ReentrancyGuard {
    address public owner;
    address public resolver;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    string public contractDetails;
    bool private initialized;
    bool public transferable; 
    
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event NFTapproval(uint256 index);
    event NFTtransfer(uint256 index);
    
    mapping(address => uint256) private balances;
    mapping(uint256 => NFT) public tokenId;
    
    struct NFT {
        address tokenOwner;
        address tokenSpender;
        string tokenDetails;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    function init(
        string calldata _name, 
        string calldata _symbol, 
        address _owner, 
        address _resolver, 
        uint256 _totalSupplyCap, 
        string calldata _contractDetails,
        string calldata tokenDetails,
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 

        name = _name; 
        symbol = _symbol; 
        owner = _owner; 
        resolver = _resolver;
        totalSupplyCap = _totalSupplyCap; 
        contractDetails = _contractDetails; 
        initialized = true; 
        transferable = _transferable; 
        balances[owner] += 1;
        totalSupply += 1;
        tokenId[totalSupply].tokenOwner = owner;
        tokenId[totalSupply].tokenSpender = owner;
        tokenId[totalSupply].tokenDetails = tokenDetails;
        
        emit Transfer(address(0), owner, 1);
        emit NFTtransfer(totalSupply);
        _initReentrancyGuard(); 
    }
    
    function approve(address spender, uint256 index) external returns (bool) {
        NFT storage nft = tokenId[index];
        require(msg.sender == nft.tokenOwner);
    
        nft.tokenSpender = spender;
        
        emit Approval(msg.sender, spender, 1); 
        emit NFTapproval(index);
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function balanceResolution(address sender, address recipient, uint256 index) external {
        require(msg.sender == resolver, "!resolver"); 
        
        _transfer(sender, recipient, index); 
    }
    
    function burn(uint256 index) external {
        NFT storage nft = tokenId[index];
        
        nft.tokenOwner = address(0);
        nft.tokenSpender = address(0);
        nft.tokenDetails = "";
        
        balances[msg.sender] -= 1; 
        totalSupply -= 1; 
        
        emit Transfer(msg.sender, address(0), 1);
    }
    
    function _transfer(address sender, address recipient, uint256 index) internal {
        NFT storage nft = tokenId[index];
        
        balances[sender] -= 1; 
        balances[recipient] += 1; 
        nft.tokenOwner = recipient;
        nft.tokenSpender = recipient;
        
        emit Transfer(sender, recipient, 1); 
        emit NFTtransfer(index);
    }
    
    function transfer(address recipient, uint256 index) external returns (bool) {
        require(transferable, "!transferable"); 
        
        _transfer(msg.sender, recipient, index);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 index) external returns (bool) {
        require(transferable, "!transferable");
        
        NFT storage nft = tokenId[index];
        require(msg.sender == nft.tokenSpender);
        nft.tokenSpender = recipient;
        
        _transfer(sender, recipient, index);
        
        return true;
    }
    
    /**************
    OWNER FUNCTIONS
    **************/
    function mint(address recipient, string calldata tokenDetails) external onlyOwner {
        balances[recipient] += 1;
        totalSupply += 1; 
        require(totalSupply + 1 <= totalSupplyCap, "capped");
        tokenId[totalSupply].tokenOwner = recipient;
        tokenId[totalSupply].tokenSpender = recipient;
        tokenId[totalSupply].tokenDetails = tokenDetails;
        
        emit Transfer(address(0), recipient, 1); 
    }
  
    function updateMessage(string calldata _contractDetails) external onlyOwner {
        contractDetails = _contractDetails;
    }
    
    function updateOwner(address payable _owner) external onlyOwner {
        owner = _owner;
    }
    
    function updateResolver(address _resolver) external onlyOwner {
        resolver = _resolver;
    }
    
    function updateTransferability(bool _transferable) external onlyOwner {
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
    function createClone(address target) internal returns (address result) {
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

contract LexNFTFactory is CloneFactory {
    address payable public lexDAO;
    address payable public template;
    bytes32 public message;
    
    constructor (address payable _lexDAO, address _template, bytes32 _message) public {
        lexDAO = _lexDAO;
        template = _template;
        message = _message;
    }
    
    function LaunchLexNFT(
        string memory _name, 
        string memory _symbol, 
        address payable _owner, 
        address _resolver, 
        uint256 _totalSupplyCap, 
        string memory _contractDetails,
        string memory tokenDetails,
        bool _transferable
    ) payable public returns (address) {
        LexNFT lexNFT = LexNFT(createClone(template));
        
        lexNFT.init(
            _name, 
            _symbol, 
            _owner, 
            _resolver, 
            _totalSupplyCap, 
            _contractDetails,
            tokenDetails,
            _transferable);
        
        (bool success, ) = lexDAO.call.value(msg.value)("");
        require(success, "!transfer");

        return address(lexNFT);
    }
    
    function updateLexDAO(address payable _lexDAO) external {
        require(msg.sender == lexDAO, "!lexDAO");
        
        lexDAO = _lexDAO;
    }
    
    function updateMessage(bytes32 _message) external {
        require(msg.sender == lexDAO, "!lexDAO");
        
        message = _message;
    }
}
