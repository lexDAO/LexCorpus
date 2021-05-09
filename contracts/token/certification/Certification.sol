/// Presented by LexDAO LLC
/// SPDX-License-Identifier: GPL-3.0-or-later
/// @notice Minimal Certification NFT.
pragma solidity 0.8.4;

contract Certification {
    address public governance;
    uint256 public totalSupply;
    string  public baseURI;
    string  public details;
    string  public name;
    string  public symbol;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // ERC-165 
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferGovernance(address indexed governance, string details);
    event GovTokenURI(uint256 indexed tokenId, string tokenURI);
    
    constructor(address _governance, string memory _baseURI, string memory _details, string memory _name, string memory _symbol) {
        governance = _governance;
        baseURI = _baseURI;
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        supportsInterface[0x80ac58cd] = true; // ERC-721 
        supportsInterface[0x5b5e139f] = true; // METADATA
    }
    
    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }
    
    function batchCall(bytes[] calldata calls, bool revertOnFail) external returns (bool[] memory successes, bytes[] memory results, string memory revertMsg) {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            successes[i] = success;
            results[i] = result;
            if (!success && revertOnFail) 
                if (result.length < 68) revertMsg = "silent";
                    assembly {result := add(result, 0x04)}
                    revertMsg = abi.decode(result, (string)); 
        }
    }
    
    function burn(address from, uint256 tokenId) external {
        require(from == ownerOf[tokenId] || from == governance, "!owner||!governance");
        balanceOf[from]--; 
        ownerOf[tokenId] = address(0);
        tokenURI[tokenId] = "";
        emit Transfer(from, address(0), tokenId); 
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
        require(tokenId <= totalSupply, "!exist");
        tokenURI[tokenId] = _tokenURI;
        emit GovTokenURI(tokenId, _tokenURI);
    }
    
    function govTransferFrom(address from, address to, uint256 tokenId) external onlyGovernance {
        require(from == ownerOf[tokenId], "from!owner");
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
}

contract CertificationFactory {
    event DeployCertification(Certification indexed certification, address indexed governance);
    
    function deployCertification(address _governance, string memory _baseURI, string calldata _details, string calldata _name, string calldata _symbol) external returns (Certification certification) {
        certification = new Certification(_governance, _baseURI, _details, _name, _symbol);
        emit DeployCertification(certification, _governance);
    }
}
