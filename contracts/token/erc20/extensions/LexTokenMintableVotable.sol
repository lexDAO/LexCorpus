// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../../LexToken.sol';
import '../../../LexOwnable.sol';

/// @notice LexToken with owned minting/burning and Compound-style governance.
contract LexTokenMintableVotable is LexToken, LexOwnable {
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    
    mapping(address => address) public delegates;
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    mapping(address => uint256) public numCheckpoints;
    
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    
    /// @notice Marks 'votes' from a given timestamp.
    struct Checkpoint {
        uint256 fromTimestamp;
        uint256 votes;
    }
    
    /// @notice Initialize owned mintable LexToken with Compound-style governance.
    /// @param _name Public name for LexToken.
    /// @param _symbol Public symbol for LexToken.
    /// @param _decimals Unit scaling factor - default '18' to match ETH units. 
    /// @param _owner Account to grant minting and burning ownership.
    /// @param _initialSupply Starting LexToken supply.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner,
        uint256 _initialSupply
    ) LexToken(_name, _symbol, _decimals) LexOwnable(_owner) {
        _mint(_owner, _initialSupply);
        _delegate(_owner, _owner);
    }

    /// @notice Mints tokens by `owner`.
    /// @param to Account to receive tokens.
    /// @param amount Sum to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        _moveDelegates(address(0), delegates[to], amount);
    }
    
    /// @notice Burns tokens by `owner`.
    /// @param from Account that has tokens burned.
    /// @param amount Sum to burn.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        _moveDelegates(delegates[from], address(0), amount);
    }
    
    /// @notice Delegate votes from `msg.sender` to `delegatee`.
    /// @param delegatee The address to delegate votes to.
    function delegate(address delegatee) external {
        _delegate(msg.sender, delegatee);
    }

    /// @notice Delegates votes from signatory to `delegatee`.
    /// @param delegatee The address to delegate votes to.
    /// @param nonce The contract state required to match the signature.
    /// @param expiry The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        
        require(signatory != address(0), "ZERO_ADDRESS");
        
        unchecked {
            require(nonce == nonces[signatory]++, "INVALID_NONCE");
        }
        
        require(block.timestamp <= expiry, "SIGNATURE_EXPIRED");
        
        _delegate(signatory, delegatee);
    }
    
    /// @notice Gets the current 'votes' balance for `account`.
    /// @param account The address to get votes balance.
    /// @return votes The number of current 'votes' for `account`.
    function getCurrentVotes(address account) external view returns (uint256 votes) {
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];
            
            votes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    /// @notice Determine the prior number of 'votes' for an `account`.
    /// @param account The address to check.
    /// @param timestamp The unix timestamp to get the 'votes' balance at.
    /// @return votes The number of 'votes' the `account` had as of the given unix timestamp.
    function getPriorVotes(address account, uint256 timestamp) external view returns (uint256 votes) {
        require(timestamp < block.timestamp, "NOT_YET_DETERMINED");
        
        uint256 nCheckpoints = numCheckpoints[account];
        
        if (nCheckpoints == 0) {
            return 0;
        }
        
        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }
            
            if (checkpoints[account][0].fromTimestamp > timestamp) {
                return 0;
            }
            
            uint256 lower;
            
            uint256 upper = nCheckpoints - 1;
            
            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;
            
                Checkpoint memory cp = checkpoints[account][center];
            
                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
        
        return checkpoints[account][lower].votes;
            
        }
    }
    
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator]; 
        
        delegates[delegator] = delegatee;
        
        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator]);
        
        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        unchecked {
            if (srcRep != dstRep && amount > 0) {
                if (srcRep != address(0)) {
                    uint256 srcRepNum = numCheckpoints[srcRep];
                    
                    uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                    
                    uint256 srcRepNew = srcRepOld - amount;
                    
                    _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
                }
                
                if (dstRep != address(0)) {
                    uint256 dstRepNum = numCheckpoints[dstRep];
                    
                    uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                    
                    uint256 dstRepNew = dstRepOld + amount;
                    
                    _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
                }
            }
        }
    }
    
    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        unchecked {
            if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(block.timestamp, newVotes);
                
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }
        
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}
