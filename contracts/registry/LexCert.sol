/*
██╗     ███████╗██╗  ██╗         
██║     ██╔════╝╚██╗██╔╝         
██║     █████╗   ╚███╔╝          
██║     ██╔══╝   ██╔██╗          
███████╗███████╗██╔╝ ██╗         
╚══════╝╚══════╝╚═╝  ╚═╝         
 ██████╗███████╗██████╗ ████████╗
██╔════╝██╔════╝██╔══██╗╚══██╔══╝
██║     █████╗  ██████╔╝   ██║   
██║     ██╔══╝  ██╔══██╗   ██║   
╚██████╗███████╗██║  ██║   ██║   
 ╚═════╝╚══════╝╚═╝  ╚═╝   ╚═╝*/
// Presented by LexDAO LLC
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC20 { // standard erc20 token interface
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
}

contract LexList {
    address public lexDAO;
    address immutable public collateral; // erc20 token claimable by burning cert.
    uint256 public totalSupply;
    string  public details;
    string  public name;
    string  public symbol;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateGovernance(address indexed lexDAO, string details);
    event UpdateTokenURI(uint256 indexed tokenId, string tokenURI);
    
    constructor(address _collateral, address _lexDAO, string memory _details, string memory _name, string memory _symbol) {
        collateral = _collateral;
        lexDAO = _lexDAO; 
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
    }
    
    modifier onlyLexDAO {
        require(msg.sender == lexDAO, "!lexDAO");
        _;
    }
    
    /// @dev burn NFT and claim fair share of collateral 
    function claim(uint256 tokenId) external {
        require(tokenId <= totalSupply, "!exist");
        uint256 balance = IERC20(collateral).balanceOf(address(this));
        IERC20(collateral).transfer(msg.sender, balance / totalSupply);
        totalSupply--;
        balanceOf[msg.sender]--;
        ownerOf[tokenId] = address(0);
        tokenURI[tokenId] = "";
        emit Transfer(msg.sender, address(0), tokenId); 
    }
    
    function _mint(address to, string calldata _tokenURI) internal { 
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenURI[tokenId] = _tokenURI;
        emit Transfer(address(0), to, tokenId); 
    }
    
    function mint(address to, string calldata _tokenURI) external onlyLexDAO { 
        _mint(to, _tokenURI);
    }
    
    function mintBatch(address[] calldata to, string[] calldata _tokenURI) external onlyLexDAO {
        require(to.length == _tokenURI.length, "!to/tokenURI");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], _tokenURI[i]); 
        }
    }
    
    function governedTransfer(address from, address to, uint256 tokenId) external onlyLexDAO {
        require(from == ownerOf[tokenId], "!owner");
        balanceOf[from]--; 
        balanceOf[to]++; 
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }
    
    function updateGovernance(address _lexDAO, string calldata _details) external onlyLexDAO {
        lexDAO = _lexDAO;
        details = _details;
        emit UpdateGovernance(_lexDAO, _details);
    }
    
    function updateTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyLexDAO {
        require(tokenId <= totalSupply, "!exist");
        tokenURI[tokenId] = _tokenURI;
        emit UpdateTokenURI(tokenId, _tokenURI);
    }
}
