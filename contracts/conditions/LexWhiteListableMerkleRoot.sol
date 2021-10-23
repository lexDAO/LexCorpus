// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./LexOwnable.sol";

// @dev library adapted from https://github.com/miguelmota/merkletreejs[merkletreejs].
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/// @notice Function whitelisting contract.
abstract contract LexWhiteListableMerkle is LexOwnable {

    using MerkleProof for bytes32[];

    event ToggleWhiteList(bool indexed whitelistEnabled);
    event UpdateWhitelist(address indexed account, bool indexed whitelisted);

    bool public whitelistEnabled;
    mapping(address => bool) public whitelisted;
    bytes32 merkleRoot;

    /// @notice Initialize contract with `whitelistEnabled` status.
    constructor(bool _whitelistEnabled, address _owner) LexOwnable(_owner) {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }

    /// @notice Whitelisting modifier that conditions modified function to be called between `whitelisted` accounts.
    modifier onlyWhitelisted(address from, address to) {
        if (whitelistEnabled)
        require(whitelisted[from] && whitelisted[to], "NOT_WHITELISTED");
        _;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function claimWhiteList(bytes32[] memory proof) public {
        require(merkleRoot != 0, "Not time to make a claim");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the whitelist");
        whitelisted[msg.sender] = true;
        emit UpdateWhitelist(msg.sender, true);
     }

    /// @notice Update account `whitelisted` status.
    /// @param account Account to update.
    /// @param _whitelisted If 'true', `account` is `whitelisted`.
    function updateWhitelist(address account, bool _whitelisted) external onlyOwner {
        whitelisted[account] = _whitelisted;
        emit UpdateWhitelist(account, _whitelisted);
    }

    /// @notice Toggle `whitelisted` conditions on/off.
    /// @param _whitelistEnabled If 'true', `whitelisted` conditions are on.
    function toggleWhitelist(bool _whitelistEnabled) external onlyOwner {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }
}
