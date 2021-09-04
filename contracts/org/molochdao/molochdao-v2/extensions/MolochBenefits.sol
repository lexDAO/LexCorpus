// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IMOLMember {
     struct Member {
        address delegateKey; // the key responsible for submitting proposals and voting - defaults to member address unless updated
        uint256 shares; // the # of voting shares assigned to this member
        uint256 loot; // the loot amount available to this member (combined with shares on ragequit)
        bool exists; // always true once a member has been created
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
        uint256 jailed; // set to proposalIndex of a passing guild kick proposal for this member, prevents voting on and sponsoring proposals
    }
    
    function members(address account) external returns (Member memory); // check member against mapping
}

contract MolochBenefits { 
    address public moloch; // moloch dao with benefits
    
    constructor(address _moloch) {
        moloch = _moloch;
    }

    function daostuff() external { // example member-restricted function
        require(IMOLMember(moloch).members(msg.sender).exists);
    }
}
