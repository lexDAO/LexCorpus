pragma solidity 0.8.4;

import "./Certification.sol";

contract CertificationFactory {
    event DeployCertification(Certification indexed certification, address indexed governance);
    
    function deployCertification(
        address _governance, 
        string calldata _baseURI, 
        string calldata _details, 
        string calldata _name, 
        string calldata _symbol
    ) external returns (Certification certification) {
        certification = new Certification(
            _governance, 
            _baseURI, 
            _details, 
            _name, 
            _symbol);
        emit DeployCertification(certification, _governance);
    }
}
