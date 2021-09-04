pragma solidity ^0.8.0;

import "../conditions/Ownable.sol";

/// @notice This contract allows for revocable signatures on an amendable ricardian template.
contract Signature is Ownable {
    uint8 public version; // counter for ricardian template versions
    string public template; // string stored for ricardian template signature - amendable by `owner`
    
    mapping(address => bool) public registered; // maps signatories to registration status (true/false)
    
    event Amend(string template);
    event Sign(string details);
    event Revoke(string details);
    
    constructor(string memory _template) {
        template = _template; // initialize ricardian template
    }
    
    function amend(string calldata _template) external onlyOwner {
        version++; // increment ricardian template version
        template = _template; // update ricardian template string stored in this contract
        emit Amend(_template); // emit amendment details in event for apps
    }

    function sign(string calldata details) external {
        registered[msg.sender] = true; // register caller signatory
        emit Sign(details); // emit signature details in event for apps
    }
    
    function revoke(string calldata details) external {
        registered[msg.sender] = false; // nullify caller registration
        emit Revoke(details); // emit revocation details in event for apps
    }
}
