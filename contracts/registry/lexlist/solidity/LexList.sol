/*
██╗     ███████╗██╗  ██╗    
██║     ██╔════╝╚██╗██╔╝    
██║     █████╗   ╚███╔╝     
██║     ██╔══╝   ██╔██╗     
███████╗███████╗██╔╝ ██╗    
╚══════╝╚══════╝╚═╝  ╚═╝    
██╗     ██╗███████╗████████╗
██║     ██║██╔════╝╚══██╔══╝
██║     ██║███████╗   ██║   
██║     ██║╚════██║   ██║   
███████╗██║███████║   ██║   
╚══════╝╚═╝╚══════╝   ╚═╝*/
// Presented by LexDAO LLC
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

contract LexList {
    address public lexDAO;
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
    
    constructor(address _lexDAO, string memory _details, string memory _name, string memory _symbol) {
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
    
    function transfer(address from, address to, uint256 tokenId) external onlyLexDAO {
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
