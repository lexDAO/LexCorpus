/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
/// @notice Basic ERC20 implementation.
contract LexGovernanceToken {
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    uint public totalSupply;
    string public baseAgreement;
    
    bytes32 public constant DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,uint chainId,address verifyingContract)'); /*EIP-712 typehash for Baal domain*/
    bytes32 public constant BALLOT_TYPEHASH = keccak256('Ballot(uint proposalId,bool support)'); /*EIP-712 typehash for ballot struct*/
    bytes32 public constant DELEGATION_TYPEHASH = keccak256('Delegation(address delegatee,uint nonce,uint expiry)'); /*EIP-712 typehash for delegation struct*/
    bytes32 public constant PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint value,uint nonce,uint deadline)'); /*EIP-712 typehash for EIP-2612 {permit}*/
    
    mapping(address => mapping(uint => Checkpoint))   public checkpoints; /*maps record of vote `checkpoints` for each account by index*/
    mapping(address => uint)                          public numCheckpoints; /*maps number of `checkpoints` for each account*/
    mapping(address => address)                       public delegates; /*maps record of each account's `shares` delegate*/
    mapping(address => uint)                          public nonces; /*maps record of states for signing & validating `shares` signatures*/
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Agreement(string agreement);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate); /*emits when an account changes its voting delegate*/
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance); /*emits when a delegate account's voting balance changes*/
    
    struct Checkpoint { /*Baal checkpoint for marking number of delegated votes from a given block*/
        uint32 fromBlock; /*block number for referencing voting balance*/
        uint96 votes; /*votes at given block number*/
    }
    
    constructor(address owner, string memory _name, string memory _symbol, uint _totalSupply, string memory _baseAgreement) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[owner] = _totalSupply;
        baseAgreement = _baseAgreement;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function approve(address to, uint amount) external returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function transfer(address to, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) 
            allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    /// @notice Delegates votes from `signatory` to `delegatee`.
    /// @param delegatee The address to delegate 'votes' to.
    /// @param nonce The contract state required to match the signature.
    /// @param expiry The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))); /*calculate EIP-712 domain hash*/
        unchecked{bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)); /*calculate EIP-712 struct hash*/
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash)); /*calculate EIP-712 digest for signature*/
        address signatory = ecrecover(digest, v, r, s); /*recover signer from hash data*/
        require(signatory != address(0),'!signature'); /*check signer is not null*/
        require(nonce == nonces[signatory]++,'!nonce'); /*check given `nonce` is next in `nonces`*/
        require(block.timestamp <= expiry,'expired'); /*check signature is not expired*/
        _delegate(signatory, delegatee);} /*execute delegation*/
    }

    /// @notice Triggers an approval from owner to spends.
    /// @param owner The address to approve from.
    /// @param spender The address to be approved.
    /// @param amount The number of tokens that are approved (2^256-1 means infinite).
    /// @param deadline The time at which to expire the signature.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permit(address owner, address spender, uint96 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))); /*calculate EIP-712 domain hash*/
        unchecked{bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline)); /*calculate EIP-712 struct hash*/
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash)); /*calculate EIP-712 digest for signature*/
        address signatory = ecrecover(digest, v, r, s); /*recover signer from hash data*/
        require(signatory != address(0),'!signature'); /*check signer is not null*/
        require(signatory == owner,'!authorized');} /*check signer is `owner`*/
        require(block.timestamp <= deadline,'expired'); /*check signature is not expired*/
        allowance[owner][spender] = amount; /*adjust `allowance`*/
        emit Approval(owner, spender, amount); /*emit event reflecting approval*/
    }
    
    /// @notice Delegate votes from caller to `delegatee`.
    /// @param delegatee The address to delegate votes to.
    function delegate(address delegatee, string calldata agreement) external {
        _delegate(msg.sender, delegatee);
        if (bytes(agreement).length > 0) {
            emit Agreement(agreement);
        }
    }
    
    /// @notice Internal function to return chain identifier per ERC-155.
    function getChainId() private view returns (uint chainId) {
        assembly {
            chainId := chainid()
        }
    }
    
    /// @notice Gets the current delegated 'vote' balance for `account`.
    function getCurrentVotes(address account) external view returns (uint96) {
        uint nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    /// @notice Determine the prior number of votes for `account` as of `blockNumber`.
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number,'!determined');
        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {return 0;}
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {return checkpoints[account][nCheckpoints - 1].votes;}
        if (checkpoints[account][0].fromBlock > blockNumber) {return 0;}
        uint lower = 0; uint upper = nCheckpoints - 1;
        while (upper > lower){
            uint center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {return cp.votes;} 
            else if (cp.fromBlock < blockNumber) {lower = center;
            } else {upper = center - 1;}}
        return checkpoints[account][lower].votes;
    }
    
    function _delegate(address delegator, address delegatee) private {
        address currentDelegate = delegates[delegator];
        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, uint96(balanceOf[delegator]));
    }
    
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) private {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                uint dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint nCheckpoints, uint96 oldVotes, uint96 newVotes) private {
        uint32 blockNumber = uint32(block.number);
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}
