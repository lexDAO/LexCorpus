// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.9;

/// @notice Interface for Moloch DAO v2 proposal.
interface IMolochV2proposal { 
    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);
}

/// @notice Interface for wrapped ether v9 (WETH9) approval & deposit.
interface IWETHv9minimal {
    function approve(address guy, uint wad) external returns (bool);
    function deposit() external payable;
}

/// @notice Single owner function access control module.
abstract contract LexOwnable {
    event TransferOwner(address indexed from, address indexed to);
    event TransferOwnerClaim(address indexed from, address indexed to);
    
    address public owner;
    address public pendingOwner;

    /// @notice Initialize ownership module for function access control.
    /// @param owner_ Account to grant ownership.
    constructor(address owner_) {
        owner = owner_;
        emit TransferOwner(address(0), owner_);
    }

    /// @notice Access control modifier that conditions function to be restricted to `owner` account.
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /// @notice `pendingOwner` can claim `owner` account.
    function claimOwner() external {
        require(msg.sender == pendingOwner, "NOT_PENDING_OWNER");
        emit TransferOwner(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /// @notice Transfer `owner` account.
    /// @param to Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address to, bool direct) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        
        if (direct) {
            owner = to;
            emit TransferOwner(msg.sender, to);
        } else {
            pendingOwner = to;
            emit TransferOwnerClaim(msg.sender, to);
        }
    }
}

/// @notice Moloch DAO v2 membership proposal tribute wrapper.
contract MolochTributeWrapper is LexOwnable(msg.sender) {
    /// @dev Using private & immutables to save gas.
    IMolochV2proposal immutable dao;
    IWETHv9minimal immutable wETH9;
    uint256 sharesForTribute;
    uint256 tributeForShares; 
    
    /// @notice Initializes contract.
    /// @param dao_ Moloch DAO v2 for membership proposals.
    /// @param wETH9_ wETH9-compatible token wrapper for native asset.
    /// @param sharesForTribute_ `DAO` 'shares' requested.
    /// @param tributeForShares_ `DAO` 'tribute' made.
    constructor(IMolochV2proposal dao_, IWETHv9minimal wETH9_, uint256 sharesForTribute_, uint256 tributeForShares_) {
        wETH9_.approve(address(dao_), type(uint256).max);
        dao = dao_;
        wETH9 = wETH9_;
        sharesForTribute = sharesForTribute_;
        tributeForShares = tributeForShares_;
    }
    
    /// @notice Fallback that submits membership proposal to `DAO` and wraps native asset to `wETH9`.
    receive() external payable {
        submitMembershipProposal("Membership");
    }
    
    /// @notice Submits membership proposal to `DAO` and wraps native asset to `wETH9`.
    /// @param details Membership details. 
    function submitMembershipProposal(string memory details) public payable {
        require(msg.value == tributeForShares, "INVALID_TRIBUTE");
        
        wETH9.deposit{value: msg.value}();
            
        dao.submitProposal(
            msg.sender,
            sharesForTribute,
            0,
            msg.value,
            address(wETH9),
            0,
            address(wETH9),
            details
        );
    }
    
    /// @notice Updates `wETH9` amount forwarded for `DAO` membership 'tribute' and 'shares' requested.
    /// @param sharesForTribute_ `DAO` 'shares' requested.
    /// @param tributeForShares_ `DAO` 'tribute' made.
    /// @dev Can only be called by `owner`.
    function updateTribute(uint256 sharesForTribute_, uint256 tributeForShares_) external onlyOwner {
        sharesForTribute = sharesForTribute_;
        tributeForShares = tributeForShares_;
    }
}
