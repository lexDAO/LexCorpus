/*
██╗     ███████╗██╗  ██╗
██║     ██╔════╝╚██╗██╔╝
██║     █████╗   ╚███╔╝ 
██║     ██╔══╝   ██╔██╗ 
███████╗███████╗██╔╝ ██╗
╚══════╝╚══════╝╚═╝  ╚═╝
██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗ 
██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗
██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝
██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗
███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
DEAR MSG.SENDER(S):

/ LXL is a project in beta.
// Please audit and use at your own risk.
/// Entry into LXL shall not create an attorney/client relationship.
//// Likewise, LXL should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W 

~presented by Open, ESQ || LexDAO LLC
*/

pragma solidity 0.5.17;

interface IERC20 { // brief interface for erc20 token txs
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library Address { // helper for address type / openzeppelin-contracts/blob/master/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

library SafeERC20 { // wrapper around erc20 token txs for non-standard contracts / openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

   function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: erc20 operation did not succeed");
        }
    }
}

library SafeMath { // wrapper over solidity arithmetic for unit under/overflow checks
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

contract Context { // describes current contract execution context (metaTX support) / openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract LexResolver is Context { // swift arbitration protocol with dispute locker
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /** <⚖️> LXL <⚖️> **/
    address public lexDAO;
    uint256 public disputeCount;
    uint256 public resolutionRate;
    uint256 public MAX_DURATION; // time limit on token lockup for dispute resolution - default 63113904 (2-year)
    mapping(uint256 => Locker) public lockers; 

    struct Locker {  
        address plaintiff; 
        address defendant;
        address resolver;
        address token;
        uint8 confirmed;
        uint8 released;
        uint256 amount;
        uint256 termination;
        string complaint;
        string response;
    }
    
    event RegisterComplaint(address indexed plaintiff, address indexed defendant, address indexed resolver, address token, uint256 amount, uint256 index, uint256 termination, string complaint);	
    event ConfirmResponse(uint256 indexed index, string response);  
    event WithdrawDeposit(uint256 indexed index);
    event ResolveDispute(address indexed resolver, uint256 indexed plaintiffAward, uint256 indexed defendantAward, uint256 resolutionFee, uint256 index, string opinion); 
    event UpdateComplaint(uint256 indexed index, string complaint);
    event UpdateResponse(uint256 indexed index, string response);
    event UpdateLockerSettings(address indexed lexDAO, uint256 indexed MAX_DURATION, uint256 indexed resolutionRate, string details);
    
    constructor (address _lexDAO, uint256 _MAX_DURATION, uint256 _resolutionRate) public {
        lexDAO = _lexDAO;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
    }

    /***************
    LOCKER FUNCTIONS
    ***************/
    function registerComplaint( // register dispute locker for token deposit & defendant confirmation
        address plaintiff,
        address defendant,
        address resolver,
        address token,
        uint256 amount,
        uint256 termination, // exact termination date in seconds since epoch
        string calldata complaint) external returns (uint256) {
        require(termination <= now.add(MAX_DURATION), "duration maxed");
        
        disputeCount = disputeCount + 1;
        uint256 index = disputeCount;
        
        lockers[index] = Locker(
            plaintiff,
            defendant,
            resolver,
            token,
            0,
            0,
            amount,
            termination,
            complaint,
            "");

        emit RegisterComplaint(plaintiff, defendant, resolver, token, amount, index, termination, complaint); 
        return index;
    }
    
    function confirmResponse(uint256 index, string calldata response) external { // defendant confirms & locks in split of dispute amount 
        Locker storage locker = lockers[index];
        
        require(locker.confirmed == 0, "confirmed");
        require(_msgSender() == locker.defendant, "!defendant");
        
        locker.response = response;
        
        uint256 split = locker.amount.div(2);
        
        IERC20(locker.token).safeTransferFrom(locker.plaintiff, address(this), split);
        IERC20(locker.token).safeTransferFrom(_msgSender(), address(this), split);

        locker.confirmed = 1; // true
        
        emit ConfirmResponse(index, response); 
    }

    function withdraw(uint256 index) external { // withdraw dispute amount deposit to plaintiff & defendant if termination time passes & no resolution
    	Locker storage locker = lockers[index];
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.released == 0, "released");
        require(now > locker.termination, "!terminated");
        
        uint256 split = locker.amount.div(2);
        
        IERC20(locker.token).safeTransferFrom(address(this), locker.plaintiff, split);
        IERC20(locker.token).safeTransferFrom(address(this), locker.defendant, split);
        
        locker.released = 1; // true
        
	emit WithdrawDeposit(index); 
    }
    
    /************
    ADR FUNCTIONS
    ************/
    function updateComplaint(uint256 index, string calldata complaint) external { 
        Locker storage locker = lockers[index];
        
        require(locker.confirmed == 1, "!confirmed");
        require(now < locker.termination, "terminated");
        require(_msgSender() == locker.plaintiff, "!plaintiff");
       
        locker.complaint = complaint;

        emit UpdateComplaint(index, complaint); 
    }
    
 
    function updateResponse(uint256 index, string calldata response) external { 
        Locker storage locker = lockers[index];
        
        require(locker.confirmed == 1, "!confirmed");
        require(now < locker.termination, "terminated");
        require(_msgSender() == locker.defendant, "!defendant");
       
        locker.response = response;

        emit UpdateResponse(index, response); 
    }
    
    
    function resolveDispute(uint256 index, uint256 plaintiffAward, uint256 defendantAward, string calldata opinion) external { // resolver splits locked deposit between plaintiff & defendant per opinion
        Locker storage locker = lockers[index];
        
	uint256 resolutionFee = locker.amount.div(resolutionRate); // calculate dispute resolution fee
	    
	require(locker.confirmed == 1, "!confirmed");
	require(locker.released == 0, "released");
	require(now < locker.termination, "terminated");
	require(_msgSender() == locker.resolver, "!resolver");
	require(_msgSender() != locker.plaintiff && _msgSender() != locker.defendant, "resolver == party");
	require(plaintiffAward.add(defendantAward) == locker.amount.sub(resolutionFee), "resolution != amount");
	    
	IERC20(locker.token).safeTransfer(locker.plaintiff, plaintiffAward);
	IERC20(locker.token).safeTransfer(locker.defendant, defendantAward);
        IERC20(locker.token).safeTransfer(locker.resolver, resolutionFee);
	    
	locker.released = 1; // true 
	    
	emit ResolveDispute(_msgSender(), plaintiffAward, defendantAward, index, resolutionFee, opinion);
    }
    
    /**************
    LEXDAO FUNCTION
    **************/
    function updateLockerSettings(address _lexDAO, uint256 _MAX_DURATION, uint256 _resolutionRate, string calldata details) external { 
        require(_msgSender() == lexDAO, "!lexDAO");
        
        lexDAO = _lexDAO;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
	    
	emit UpdateLockerSettings(lexDAO, MAX_DURATION, resolutionRate, details);
    }
}
