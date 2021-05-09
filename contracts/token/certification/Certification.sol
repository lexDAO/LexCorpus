/// Presented by LexDAO LLC
/// SPDX-License-Identifier: GPL-3.0-or-later
/// @notice Minimal Certification NFT.
pragma solidity 0.8.4;

contract Certification {
    address public duesToken;
    address public governance;
    uint256 public duesAmount;
    uint256 public duesPeriod;
    uint256 public totalSupply;
    string  public baseURI;
    string  public details;
    string  public name;
    string  public symbol;
    bytes4  constant SIG_TRANSFER = 0xa9059cbb; // erc20 function signature for simple 'safe transfer' - transfer(address,uint)
    bytes4  constant SIG_TRANSFER_FROM = 0x23b872dd; // erc20 function signature simple 'safe transferFrom' - transferFrom(address,address,uint)
    
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public goodStanding;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // ERC-165 
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferGovernance(address indexed governance, string details);
    event GovTokenURI(uint256 indexed tokenId, string tokenURI);
    
    constructor(
        address _duesToken, 
        address _governance, 
        uint256 _duesAmount,
        uint256 _duesPeriod,
        string memory _baseURI, 
        string memory _details, 
        string memory _name, 
        string memory _symbol
    ) {
        duesToken = _duesToken;
        governance = _governance;
        duesAmount = _duesAmount;
        duesPeriod = _duesPeriod;
        baseURI = _baseURI;
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        supportsInterface[0x80ac58cd] = true; // ERC-721 
        supportsInterface[0x5b5e139f] = true; // METADATA
    }
    
    modifier onlyGovernance {
        require(msg.sender == governance, '!governance');
        _;
    }
    
    function batchCall(bytes[] calldata calls, bool revertOnFail) external returns (string memory revertMsg) {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) 
                if (result.length < 68) revertMsg = 'silent';
                    assembly {result := add(result, 0x04)}
                    revertMsg = abi.decode(result, (string)); 
        }
    }
    
    function burn(address from, uint256 tokenId) external {
        require(from == ownerOf[tokenId] || from == governance, '!owner||!governance');
        balanceOf[from]--; 
        ownerOf[tokenId] = address(0);
        tokenURI[tokenId] = "";
        emit Transfer(from, address(0), tokenId); 
    }
    
    function checkDues(uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        if (!goodStanding[owner])
        balanceOf[owner]--; 
        ownerOf[tokenId] = address(0);
        tokenURI[tokenId] = "";
        emit Transfer(owner, address(0), tokenId); 
    }
    
    function depositDues() external payable {
        if (duesToken == address(0)) { 
            require(msg.value == duesAmount);
        } else {
            (bool success, bytes memory data) = duesToken.call(abi.encodeWithSelector(SIG_TRANSFER, msg.sender, address(this), duesAmount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer fail');
        }
        goodStanding[msg.sender] = true;
    }

    function mint(address to, string calldata customURI) external onlyGovernance { 
        string memory _tokenURI; 
        bytes(customURI).length > 0 ? _tokenURI = customURI : _tokenURI = baseURI;
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenURI[tokenId] = _tokenURI;
        emit Transfer(address(0), to, tokenId);
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

    function transferGovernance(address _governance, string calldata _details) external onlyGovernance {
        governance = _governance;
        details = _details;
        emit TransferGovernance(_governance, _details);
    }
    
    function updateDues(address _duesToken, uint256 _duesAmount, uint256 _duesPeriod) external onlyGovernance {
        duesToken = _duesToken;
        duesAmount = _duesAmount;
        duesPeriod = _duesPeriod;
    }
    
    function withdrawDues() external onlyGovernance {
        if (duesToken == address(0)) { 
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "!payable");
        } else {
            (bool success, bytes memory data) = duesToken.call(abi.encodeWithSelector(SIG_TRANSFER, msg.sender, duesAmount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer fail');
        }
    }
}

contract CertificationFactory {
    event DeployCertification(Certification indexed certification, address indexed governance);
    
    function deployCertification(
        address _duesToken, 
        address _governance, 
        uint256 _duesAmount, 
        uint256 _duesPeriod, 
        string memory _baseURI, 
        string memory _details, 
        string memory _name, 
        string memory _symbol
    ) external returns (Certification certification) {
        certification = new Certification(_duesToken, _governance, _duesAmount, _duesPeriod, _baseURI, _details, _name, _symbol);
        emit DeployCertification(certification, _governance);
    }
}
