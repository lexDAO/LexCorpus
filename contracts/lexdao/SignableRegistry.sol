// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Protocol for registering content and signatures.
contract SignableRegistry {
    event Sign(address indexed signer, uint256 indexed index);
    event Revoke(address indexed revoker, uint256 indexed index);
    event Register(address indexed author, string indexed content);
    event Amend(address indexed author, uint256 indexed index, string indexed content);
    
    /// @dev EIP-712 variables:
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant SIG_HASH = keccak256("SignMeta(address signer,uint256 index)");
    
    /// @dev Signable counter and struct mapping:
    uint256 public signablesCount;
    
    mapping(uint256 => Signable) signables;
    
    struct Signable {
        address author;
        string content;
        mapping(address => bool) signed;
    }
    
    /// @dev Initialize contract and `DOMAIN_SEPARATOR`.
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SignableRegistry")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    // **** SIGNING PROTOCOL **** //
    // ------------------------- //
    
    /// @notice Check an `account` for signature against indexed `content`.
    /// @param account Address to check signature for.
    /// @param index `content` # to check signature against.
    function checkSignature(address account, uint256 index) external view returns (bool signed) {
        signed = signables[index].signed[account];
    }
    
    // **** SIGNING
    
    /// @notice Register signature against indexed `content`.
    /// @param index `content` # to map signature against.
    function sign(uint256 index) external {
        signables[index].signed[msg.sender] = true;
        emit Sign(msg.sender, index);
    }
    
    /// @notice Register signature against indexed `content` using EIP-712 metaTX.
    /// @param account Address to register signature for.
    /// @param index `content` # to map signature against.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function signMeta(address account, uint256 index, uint8 v, bytes32 r, bytes32 s) external {
        // Validate signature elements:
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SIG_HASH,
                            account,
                            index
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == account, "INVALID_SIG");
        // Register signature:
        signables[index].signed[account] = true;
        emit Sign(account, index);
    }
    
    // **** REVOCATION
    
    /// @notice Revoke signature against indexed `content`.
    /// @param index `content` # to map signature revocation against.
    function revoke(uint256 index) external {
        signables[index].signed[msg.sender] = false;
        emit Revoke(msg.sender, index);
    }
    
    /// @notice Revoke signature against indexed `content` using EIP-712 metaTX.
    /// @param account Address to revoke signature for.
    /// @param index `content` # to map signature revocation against.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function revokeMeta(address account, uint256 index, uint8 v, bytes32 r, bytes32 s) external {
        // Validate revocation elements:
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SIG_HASH,
                            account,
                            index
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == account, "INVALID_SIG");
        // Register revocation:
        signables[index].signed[account] = false;
        emit Revoke(account, index);
    }
    
    // **** REGISTRY PROTOCOL **** //
    // -------------------------- //
    
    /// @notice Register `content` for signatures.
    /// @param content Signable string - could be IPFS hash, plaintext, or JSON.
    function register(string calldata content) external {
        signablesCount++;
        uint256 index = signablesCount;
        signables[index].author = msg.sender;
        signables[index].content = content;
        emit Register(msg.sender, content);
    }
    
    /// @notice Update `content` for signatures - only callable by `author`.
    /// @param index `content` # to update.
    /// @param content Signable string - could be IPFS hash, plaintext, or JSON.
    function amend(uint256 index, string calldata content) external {
        require(msg.sender == signables[index].author, "NOT_AUTHOR");
        signables[index].content = content;
        emit Amend(msg.sender, index, content);
    }
}
