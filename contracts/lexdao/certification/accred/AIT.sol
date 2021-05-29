/// SPDX-License-Identifier: MIT
/// Presented by LexDAO LLC
/// @notice Minimal Certification NFT for Accredited Investors.
pragma solidity 0.8.4;

contract Accreditation {
    address public governance;
    uint256 public totalSupply;
    string  public baseURI;
    string  public details;
    string  public template;
    string  constant public name = "Accredited Investor Token";
    string  constant public symbol = "AIT";
    
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public attorney;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public stamp;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // ERC-165 
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event GovTokenURI(uint256 indexed tokenId, string tokenURI);
    event TransferGovernance(address indexed governance);
    event UpdateBase(string baseURI, string details, string template);
    event WhitelistAttorney(address indexed account, bool approved);
    
    constructor(
        address _governance,
        string memory _baseURI, 
        string memory _details, 
        string memory _template
    ) {
        governance = _governance;
        baseURI = _baseURI;
        details = _details; 
        template = _template;
        supportsInterface[0x80ac58cd] = true; // ERC-721 
        supportsInterface[0x5b5e139f] = true; // METADATA
    }

    modifier onlyGovernance {
        require(msg.sender == governance, '!governance');
        _;
    }
    
    function burn(address from, uint256 tokenId) external {
        require(from == ownerOf[tokenId] || from == governance, '!owner||!governance');
        balanceOf[from]--; 
        ownerOf[tokenId] = address(0);
        tokenURI[tokenId] = "";
        emit Transfer(from, address(0), tokenId); 
    }
    
    function mint(address to, string calldata customURI) external { 
        require(attorney[msg.sender], '!attorney');
        string memory _tokenURI; 
        bytes(customURI).length > 0 ? _tokenURI = customURI : _tokenURI = baseURI;
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        stamp[tokenId] = block.timestamp;
        tokenURI[tokenId] = _tokenURI;
        emit Transfer(address(0), to, tokenId);
    }
    
    function renew(uint256 tokenId) external {
        require(tokenId <= totalSupply, '!exist');
        require(attorney[msg.sender], '!attorney');
        stamp[tokenId] = block.timestamp;
    }

    function govTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyGovernance {
        require(tokenId <= totalSupply, '!exist');
        tokenURI[tokenId] = _tokenURI;
        emit GovTokenURI(tokenId, _tokenURI);
    }
    
    function govTransferFrom(address from, address to, uint256 tokenId) external onlyGovernance {
        require(from == ownerOf[tokenId], 'from!=owner');
        balanceOf[from]--; 
        balanceOf[to]++; 
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }

    function transferGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit TransferGovernance(_governance);
    }
    
    function updateBase(string calldata _baseURI, string calldata _details, string calldata _template) external onlyGovernance {
        baseURI = _baseURI;
        details = _details;
        template = _template;
        emit UpdateBase(_baseURI, _details, _template);
    }
    
    function whitelistAttorney(address account, bool approved) external onlyGovernance {
        attorney[account] = approved;
        emit WhitelistAttorney(account, approved);
    }
}
