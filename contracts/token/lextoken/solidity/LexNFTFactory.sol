pragma solidity 0.5.17;

contract LexNFT {
    address public owner;
    address public resolver;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    string public baseURI;
    string public name;
    string public symbol;
    bool private initialized;
    bool private _notEntered;
    bool public transferable; 

    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;

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
        string calldata _baseURI,
        string calldata tokenURI,
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 

        name = _name; 
        symbol = _symbol; 
        owner = _owner; 
        resolver = _resolver;
        totalSupplyCap = _totalSupplyCap; 
        baseURI = _baseURI; 
        initialized = true; 
        transferable = _transferable; 
        
        balanceOf[owner] += 1;
        totalSupply += 1;
        ownerOf[totalSupply] = owner;
        tokenByIndex[totalSupply] = totalSupply;
        tokenURI[totalSupply] = tokenURI;
        tokenOfOwnerByIndex[owner][totalSupply];
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
        _initReentrancyGuard();
        
        emit Transfer(address(0), owner, totalSupply);
    }
   
    /************
    TKN FUNCTIONS
    ************/
    function approve(address spender, uint256 tokenId) external returns (bool) {
        address tokenOwner = ownerOf[tokenId];
        require(msg.sender == tokenOwner || isApprovedForAll[tokenOwner][msg.sender], "!owner/approvedForAll");
        
        getApproved[tokenId] = spender;
        
        emit Approval(msg.sender, spender, tokenId); 
        
        return true;
    }
    
    function setApprovalForAll(address spender, bool approved) external returns (bool) {
        isApprovedForAll[msg.sender][spender] = approved;
        
        emit ApprovalForAll(msg.sender, spender, approved);
        
        return true;
    }

    function balanceResolution(address sender, address recipient, uint256 tokenId) external {
        require(msg.sender == resolver, "!resolver");
        require(sender == ownerOf[tokenId], "!owner");
        
        _transfer(sender, recipient, tokenId); 
    }
    
    function burn(uint256 tokenId) external {
        address tokenOwner = ownerOf[tokenId];
        require(msg.sender == tokenOwner || getApproved[tokenId] == msg.sender || isApprovedForAll[tokenOwner][msg.sender], "!owner/spender/approvedForAll");
        
        balanceOf[tokenOwner] -= 1;
        totalSupply -= 1; 
        ownerOf[tokenId] = address(0);
        getApproved[tokenId] = address(0);
        tokenURI[tokenId] = "";
        
        emit Transfer(msg.sender, address(0), tokenId);
    }
    
    function burnBatch(uint256[] calldata tokenId) external {
        for (uint256 i = 0; i < tokenId.length; i++) {
            burn(tokenId[i]);
        }
    }
    
    function _transfer(address sender, address recipient, uint256 tokenId) internal {
        balanceOf[sender] -= 1; 
        balanceOf[recipient] += 1; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = recipient;
        
        emit Transfer(sender, recipient, tokenId); 
    }
    
    function transfer(address recipient, uint256 tokenId) external returns (bool) {
        require(msg.sender == ownerOf[tokenId], "!owner");
        require(transferable, "!transferable"); 
        
        _transfer(msg.sender, recipient, tokenId);
        
        return true;
    }
    
    function transferBatch(address[] calldata recipient, uint256[] calldata tokenId) external {
        require(transferable, "!transferable"); 
        require(recipient.length == tokenId.length, "!recipient/index");
        
        for (uint256 i = 0; i < recipient.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            _transfer(msg.sender, recipient[i], tokenId[i]);
        }
    }

    function transferFrom(address sender, address recipient, uint256 tokenId) public returns (bool) {
        address tokenOwner = ownerOf[tokenId];
        require(msg.sender == tokenOwner || getApproved[tokenId] == msg.sender || isApprovedForAll[tokenOwner][msg.sender], "!owner/spender/approvedForAll");
        require(transferable, "!transferable");

        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = recipient;
        
        _transfer(sender, recipient, tokenId);
        
        return true;
    }
    
    function safeTransferFrom(address sender, address recipient, uint256 tokenId) external {
        safeTransferFrom(sender, recipient, tokenId, "");
    }
    
    function safeTransferFrom(address sender, address recipient, uint256 tokenId, bytes memory data) public {
        _callOptionalReturn(recipient, data);
        transferFrom(sender, recipient, tokenId);
    }
    
    /**************
    OWNER FUNCTIONS
    **************/
    function mint(address recipient, string calldata tokenDetails) external onlyOwner {
        totalSupply += 1; 
        require(totalSupply <= totalSupplyCap, "capped");
        
        balanceOf[recipient] += 1;
        ownerOf[totalSupply] = recipient;
        tokenURI[totalSupply] = tokenDetails;
        
        emit Transfer(address(0), recipient, totalSupply); 
    }
    
    function updateBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    
    function updateTokenURI(uint256 tokenId, string calldata tokenURI) external onlyOwner {
        tokenURI[tokenId] = tokenURI;
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

    /***************
    HELPER FUNCTIONS
    ***************/
    function _callOptionalReturn(address recipient, bytes memory data) internal {
        require(isContract(recipient), "SafeERC20: call to non-contract");

        (bool success, bytes memory returnData) = recipient.call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returnData.length > 0) { // return data is optional
            require(abi.decode(returnData, (bool)), "SafeERC20: erc20 operation did not succeed");
        }
    }
    
    function _initReentrancyGuard() internal {
        _notEntered = true;
    }
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
    address public template;
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
