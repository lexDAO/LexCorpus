// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../../interfaces/IERC20.sol";

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
