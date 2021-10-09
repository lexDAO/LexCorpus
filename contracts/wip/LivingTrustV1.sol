// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

/// @notice Standard ERC-20 token interface with EIP-2612 {permit} extension.
interface IERC20 { 
    /// @dev ERC-20:
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function totalSupply() external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    /// @dev EIP-2612:
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

/// @dev Hacked by LexDAO LLC.
contract LivingTrustV1 {
    address public grantor; // supplies funds to vault - initial trustee
    address public beneficiary; // can claim trust funds - initially grantor
    address public successorTrustee;
    address public trustee; // @dev Updates to successor trustee following dead man switch
    
    uint256 public lastDeadManSwitched; // timestamp tracking last dead man switch call
    
    constructor(address _grantor, address _beneficiary, address _trustee, address _successorTrustee) {
         grantor = _grantor;
         beneficiary = _beneficiary;
         trustee = _trustee;
         successorTrustee = _successorTrustee;
    }
    
    function deadManSwitch() external {
        require(grantor == msg.sender);
        lastDeadManSwitched = block.timestamp;
    }
    
    function claimTrust() external {
        if (30 days > lastDeadManSwitched) {
            trustee = successorTrustee;
        }
    }
    
    function distribute(IERC20 asset, uint256 amount, address destination) external {
        require(trustee == msg.sender || grantor == msg.sender);
        asset.transfer(destination, amount);
    }
    
    function transferRoles(address _grantor, address _beneficiary, address _successorTrustee, address _trustee) external {
        grantor = _grantor;
        beneficiary = _beneficiary;
        successorTrustee = _successorTrustee;
        trustee = _trustee;
    }
}
