/*
|| <🏛️> Smart Co. Operating Agreement (SCOA) <🏛️> ||

DEAR MSG.SENDER(S):

/ SCOA is a project in beta.
// Please audit and use at your own risk.
/// Entry into SCOA shall not create an attorney/client relationship.
//// Likewise, SCOA should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W

~presented by Open, ESQ || lexDAO LLC
*/

pragma solidity 0.5.17;

/***************
SMART CO. OPERATING AGREEMENT
> `Operating Agreement for Delaware Smart Co.`
***************/
contract OperatingAgreement {
    address payable public lexDAO;
    uint256 public filingFee;
    uint256 public sigFee;
    uint256 public version;
    string public terms;

    // Signature tracking: 
    uint256 public signature;
    mapping (uint256 => Signature) public sigs;

    struct Signature {
        address signatory;
        uint256 number;
        uint256 version;
        string terms;
        string details;
        bool filed;
    }

    event Amended(uint256 indexed version, bytes32 indexed terms);
    event Filed(address indexed signatory, uint256 indexed number, bytes32 indexed details);
    event Signed(address indexed signatory, uint256 indexed number, bytes32 indexed details);
    event Upgraded(address indexed signatory, uint256 indexed number, bytes32 indexed details);
    event LexDAOProposed(address indexed proposedLexDAO, bytes32 indexed details);
    event LexDAOTransferred(address indexed lexDAO, bytes32 indexed details);

    constructor(address payable _lexDAO, uint256 _filingFee, uint256 _sigFee, bytes32 memory _terms) public {
        lexDAO = _lexDAO;
        filingFee = _filingFee;
        sigFee = _sigFee;
        terms = _terms;
    }

    /******************
    SMART CO. FUNCTIONS
    ******************/
    function fileCo(uint256 number, bytes details) payable public {
        require(msg.value == filingFee);
	Signature storage sig = sigs[number];
        require(msg.sender == sig.signatory);

        sig.filed = true;

        address(lexDAO).transfer(msg.value);

        emit Filed(msg.sender, number, details);
    }

    function signTerms(bytes32 details) payable public {
        require(msg.value == sigFee);
	uint256 number += signature;
	signature += signature;

        sigs[number] = Signature(
                msg.sender,
                number,
                version,
                terms,
                details,
                false);

        address(lexDAO).transfer(msg.value);

        emit Signed(msg.sender, number, details);
    }

    function upgradeSignature(uint256 number, bytes32 details) payable public {
        Signature storage sig = sigs[number];
        require(msg.sender == sig.signatory);

        sig.version = version;
        sig.terms = terms;
        sig.details = details;

        address(lexDAO).transfer(msg.value);

        emit Upgraded(msg.sender, number, details);
    }

    /***************
    MGMT FUNCTIONS
    ***************/
    modifier onlyLexDAO() {
        require(msg.sender == lexDAO, "not lexDAO");
        _;
    }

    function amendTerms(string memory _terms) public onlyLexDAO {
        version += version;
        terms = _terms;

        emit Amended(version, terms);
    }

    function newFilingFee(uint256 weiAmount) public onlyLexDAO {
        filingFee = weiAmount;
    }

    function newSigFee(uint256 weiAmount) public onlyLexDAO {
        sigFee = weiAmount;
    }

    function transferLexDAO(address payable _lexDAO, bytes32 details) public {
        lexDAO = _lexDAO;
        emit LexDAOTransferred(lexDAO, details);
    }
}
