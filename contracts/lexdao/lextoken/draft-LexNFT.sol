// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

interface IERC721transferFrom { // brief interface for erc721 token (nft)
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract LexNFT {
    address public manager;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    string  public baseURI;
    string  public details;
    string  public name;
    string  public symbol;
    bool    private initialized; // internally tracks token deployment under eip-1167 proxy pattern
    bool    public transferable; // transferability of token - does not affect token sale - updateable by manager
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => Sale) public sale;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed holder, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateBaseURI(string baseURI, string details);
    event UpdateGovernance(address indexed manager, string details);
    event UpdateSale(uint256 ethPrice, uint256 tokenId, bool forSale);
    event UpdateTokenURI(uint256 indexed tokenId, string tokenURI, string details);
    event UpdateTransferability(bool transferable);
    
    struct Sale {
        uint256 ethPrice;
        bool forSale;
    }
    
    function init(
        address _manager,
        uint256 _managerSupply,
        uint256 _saleRate,
        uint256 _saleSupply,
        uint256 _totalSupplyCap,
        string calldata _details,
        string calldata _name,
        string calldata _symbol,
        bool _forSale,
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 
        manager = _manager; 
        totalSupplyCap = _totalSupplyCap; 
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        initialized = true; 
        transferable = _transferable; 
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
    }
    
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        tokenOfOwnerByIndex[from][tokenId - 1] = 0;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(from, to, tokenId); 
    }
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        require(transferable, "!transferable"); 
        _transfer(msg.sender, to, tokenId);
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata tokenId) external {
        require(to.length == tokenId.length, "!to/tokenId");
        require(transferable, "!transferable"); 
        for (uint256 i = 0; i < to.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            _transfer(msg.sender, to[i], tokenId[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        require(transferable, "!transferable"); 
        _transfer(from, to, tokenId);
    }
    
    function updateSale(uint256 ethPrice, uint256 tokenId, bool forSale) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    
    /****************
    MANAGER FUNCTIONS
    ****************/
    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }
    
    function _mint(address to, uint256 ethPrice, string memory _tokenURI, bool base, bool forSale) internal { 
        totalSupply++;
        require(totalSupply <= totalSupplyCap, "capped");
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenByIndex[tokenId - 1] = tokenId;
        //string memory URI = tokenURI;
        if (base) {tokenURI[tokenId] = _tokenURI;}
        tokenURI[tokenId] = _tokenURI;
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(address(0), to, tokenId); 
    }
    
    function mint(address to, uint256 ethPrice, string calldata _tokenURI, bool baseURI, bool forSale) external onlyManager { 
        _mint(to, ethPrice, _tokenURI, baseURI, forSale);
    }
    
    //function mintBatch(address[] calldata to, string[] calldata _tokenURI) external onlyManager {
    //    require(to.length == _tokenURI.length, "!to/tokenURI");
    //    for (uint256 i = 0; i < to.length; i++) {
    //        _mint(to[i], 0, _tokenURI[i], false, false); 
    //    }
    //}
    
    function updateBaseURI(string calldata _baseURI, string calldata _details) external onlyManager {
        baseURI = _baseURI;
        emit UpdateBaseURI(_baseURI, _details);
    }
    
    function updateGovernance(address payable _manager, string calldata _details) external onlyManager {
        manager = _manager;
        details = _details;
        emit UpdateGovernance(_manager, _details);
    }
    
    function updateTokenURI(uint256 tokenId, string calldata _tokenURI, string calldata details) external onlyManager {
        tokenURI[tokenId] = _tokenURI;
        emit UpdateTokenURI(tokenId, _tokenURI, details);
    }
    
    function updateTransferability(bool _transferable) external onlyManager {
        transferable = _transferable;
        emit UpdateTransferability(_transferable);
    }
    
    function withdrawNFT(address[] calldata nft, address[] calldata withrawTo, uint256[] calldata tokenId) external onlyManager { // withdraw NFT sent to contract
        require(nft.length == withrawTo.length && nft.length == tokenId.length, "!nft/withdrawTo/tokenId");
        for (uint256 i = 0; i < nft.length; i++) {
            IERC721transferFrom(nft[i]).transferFrom(address(this), withrawTo[i], tokenId[i]);
        }
    }
}
