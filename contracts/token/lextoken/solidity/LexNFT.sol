pragma solidity 0.7.4;

interface IERC721transferFrom { // brief interface for erc721 token (nft)
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract LexNFT {
    address payable public manager;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
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
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed holder, address indexed operator, bool approved);
    event Redeem(uint256 indexed tokenId, string details);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateGovernance(address indexed manager, string details);
    
    //* TO DO -
    function init(string memory _masterOperatingAgreement) public {
        ricardianLLCdao = msg.sender;
        masterOperatingAgreement = _masterOperatingAgreement;
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
    }//
    
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
        _transfer(msg.sender, to, tokenId);
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata tokenId) external {
        require(to.length == tokenId.length, "!to/tokenId");
        for (uint256 i = 0; i < to.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            _transfer(msg.sender, to[i], tokenId[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        _transfer(from, to, tokenId);
    }
    
    /****************
    MANAGER FUNCTIONS
    ****************/
    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }
    
    function mint(address to, string calldata tokenURI) payable external onlyManager { 
        totalSupply++;
        require(totalSupply <= totalSupplyCap, "capped");
        uint256 tokenId = totalSupply;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenByIndex[tokenId - 1] = tokenId;
        tokenURI[tokenId] = tokenURI;
        tokenOfOwnerByIndex[msg.sender][tokenId - 1] = tokenId;
        emit Transfer(address(0), msg.sender, tokenId); 
    }
    
    function updateGovernance(address payable _manager, string calldata _details) external onlyManager {
        manager = _manager;
        details = _details;
        emit UpdateGovernance(_manager, _details);
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
