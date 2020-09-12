/*
██████╗  █████╗ ██╗██████╗                           
██╔══██╗██╔══██╗██║██╔══██╗                          
██████╔╝███████║██║██║  ██║                          
██╔══██╗██╔══██║██║██║  ██║                          
██║  ██║██║  ██║██║██████╔╝                          
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝                                                                             
██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗     
██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    
██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝    
██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗    
███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║    
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
DEAR MSG.SENDER(S):
/ RL is a project in beta.
// Please audit & use at your own risk.
/// Entry into RL shall not create an attorney/client relationship.
//// Likewise, RL should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W 
~presented by LexDAO | Raid Guild LLC
*/

pragma solidity 0.5.17;

interface IERC20 { // brief interface for erc20 token tx
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWETH { // brief interface for canonical ether token wrapper 
    function deposit() payable external;
    
    function transfer(address dst, uint wad) external returns (bool);
}

library Address { // helper for address type - see openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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

library SafeERC20 { // wrapper around erc20 token tx for non-standard contract - see openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

   function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returnData) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returnData.length > 0) { // return data is optional
            require(abi.decode(returnData, (bool)), "SafeERC20: erc20 operation did not succeed");
        }
    }
}

library SafeMath { // arithmetic wrapper for unit under/overflow check
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

contract Context { // describe current contract execution context (metaTX support) / openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ReentrancyGuard { // call wrapper for reentrancy check
    bool private _notEntered;

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");

        _notEntered = false;

        _;

        _notEntered = true;
    }
}

contract RaidLocker is Context, ReentrancyGuard { // multi-pay / milestone locker registry w/ ADR for guild dealing
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /** <⚔️> RL <$> **/
    address public governor;
    address public swiftArbToken;
    address public wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // canonical ether token wrapper contract reference
    uint256 public lockerCount;
    uint256 public MAX_DURATION; // time limit on token lockup - default 63113904 (2-year)
    uint256 public resolutionRate;
    uint256 public swiftArbTokenBalance;
    string public lockerStamp;
    mapping(uint256 => Locker) public lockers;

    struct Locker {  
        address client; 
        address[] provider;
        address resolver;
        address token;
        uint8 confirmed;
        uint8 locked;
        uint8 swiftArb;
        uint256[] batch;
        uint256 cap;
        uint256 released;
	uint256 resolutionRate;
        uint256 termination;
        string details; 
    }
    
    event RegisterLocker(address indexed client, address[] indexed provider, address indexed resolver, address token, uint8 swiftArb, uint256[] batch, uint256 cap, uint256 index, uint256 termination, string details);
    event DepositLocker(address indexed client, address[] indexed provider, address indexed resolver, address token, uint8 swiftArb, uint256[] batch, uint256 cap, uint256 index, uint256 termination, string details);
    event ConfirmLocker(uint256 indexed index, uint256 indexed sum);  
    event Release(uint256 indexed index, uint256[] indexed milestone); 
    event Withdraw(uint256 indexed index, uint256 indexed remainder);
    event Lock(address indexed sender, uint256 indexed index, string indexed details);
    event Resolve(address indexed resolver, uint256 indexed clientAward, uint256[] indexed providerAward, uint256 index, uint256 resolutionFee, string resolution); 
    event UpdateLockerSettings(address indexed governor, address swiftArbToken, uint256 indexed MAX_DURATION, uint256 indexed resolutionRate, uint256 swiftArbTokenBalance, string lockerStamp);
    
    constructor (address _governor, address _swiftArbToken, uint256 _swiftArbTokenBalance, uint256 _MAX_DURATION, uint256 _resolutionRate, string memory _lockerStamp) public {
        governor = _governor;
        swiftArbToken = _swiftArbToken;
        swiftArbTokenBalance = _swiftArbTokenBalance;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        lockerStamp = _lockerStamp;
    }

    /***************
    LOCKER FUNCTIONS
    ***************/
    function registerLocker( // PROVIDER-TRACK: register locker for token deposit & client deal confirmation
        address client,
        address[] memory provider,
        address resolver,
        address token,
        uint8 swiftArb, // allow swiftArbToken balance holder to resolve
        uint256[] memory batch, 
        uint256 cap,
        uint256 milestones,
        uint256 termination, // exact termination date in seconds since epoch
        string memory details) public returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < provider.length; i++) {
            sum = sum.add(batch[i]);
        }
        
        require(sum.mul(milestones) == cap, "deposit != milestones");
        require(termination <= now.add(MAX_DURATION), "duration maxed");
        
        lockerCount = lockerCount + 1;
        uint256 index = lockerCount;
        
        lockers[index] = Locker( 
            client, 
            provider,
            resolver,
            token,
            0,
            0,
            swiftArb,
            batch,
            cap,
            0,
	    resolutionRate,
            termination,
            details);

        emit RegisterLocker(client, provider, resolver, token, swiftArb, batch, cap, index, termination, details); 
        return index;
    }
    
    function confirmLocker(uint256 index) payable external nonReentrant { // PROVIDER-TRACK: client confirms deposit of cap & locks in deal
        Locker storage locker = lockers[index];
        
        require(locker.confirmed == 0, "confirmed");
        require(_msgSender() == locker.client, "!client");
        
        uint256 sum = locker.cap;
        
        if (locker.token == wETH && msg.value > 0) {
            require(msg.value == sum, "!ETH");
            IWETH(wETH).deposit();
            (bool success, ) = wETH.call.value(msg.value)("");
            require(success, "!transfer");
            IWETH(wETH).transfer(address(this), msg.value);
        } else {
            IERC20(locker.token).safeTransferFrom(msg.sender, address(this), sum);
        }
        
        locker.confirmed = 1;
        
        emit ConfirmLocker(index, sum); 
    }
    
    function depositLocker( // CLIENT-TRACK: register locker w/ token deposit & provider deal confirmation via deal performance
        address[] memory provider,
        address resolver,
        address token,
        uint8 swiftArb, // allow swiftArbToken balance holder to resolve
        uint256[] memory batch, 
        uint256 cap,
        uint256 milestones,
        uint256 termination, // exact termination date in seconds since epoch
        string memory details) payable public nonReentrant returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < provider.length; i++) {
            sum = sum.add(batch[i]);
        }
        
        require(sum.mul(milestones) == cap, "deposit != milestones");
        require(termination <= now.add(MAX_DURATION), "duration maxed");
        
        if (token == wETH && msg.value > 0) {
            require(msg.value == cap, "!ETH");
            IWETH(wETH).deposit();
            (bool success, ) = wETH.call.value(msg.value)("");
            require(success, "!transfer");
            IWETH(wETH).transfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), cap);
        }
        
        lockerCount = lockerCount + 1;
        uint256 index = lockerCount;
        
        lockers[index] = Locker( 
            _msgSender(), 
            provider,
            resolver,
            token,
            swiftArb,
            1,
            0,
            batch,
            cap,
            0,
	    resolutionRate,
            termination,
            details);

        emit DepositLocker(_msgSender(), provider, resolver, token, swiftArb, batch, cap, index, termination, details); 
        return index;
    }

    function release(uint256 index) external nonReentrant { // client transfers locker milestone batch to provider(s) 
    	Locker storage locker = lockers[index];
	    
	require(_msgSender() == locker.client, "!client");
	require(locker.confirmed == 1, "!confirmed");
	require(locker.locked == 0, "locked");
	require(locker.cap > locker.released, "released");
        
        uint256[] memory milestone = locker.batch;
        
        for (uint256 i = 0; i < locker.provider.length; i++) {
            IERC20(locker.token).safeTransfer(locker.provider[i], milestone[i]);
            locker.released = locker.released.add(milestone[i]);
        }

	emit Release(index, milestone); 
    }
    
    function withdraw(uint256 index) external nonReentrant { // withdraw locker remainder to client if termination time passes & no lock
    	Locker storage locker = lockers[index];
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.locked == 0, "locked");
        require(locker.cap > locker.released, "released");
        require(now > locker.termination, "!terminated");
        
        uint256 remainder = locker.cap.sub(locker.released); 
        
        IERC20(locker.token).safeTransfer(locker.client, remainder);
        
        locker.released = locker.released.add(remainder); 
        
	emit Withdraw(index, remainder); 
    }
    
    /************
    ADR FUNCTIONS
    ************/
    function lock(uint256 index, string calldata details) external { // client or main (0) provider can lock remainder for resolution during locker period / update request details
        Locker storage locker = lockers[index]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.cap > locker.released, "released");
        require(now < locker.termination, "terminated"); 
        require(_msgSender() == locker.client || _msgSender() == locker.provider[0], "!party"); 

	locker.locked = 1; 
	    
	emit Lock(_msgSender(), index, details);
    }
    
    function resolve(uint256 index, uint256 clientAward, uint256[] calldata providerAward, string calldata resolution) external nonReentrant { // resolver splits locked deposit remainder between client & provider(s)
        Locker storage locker = lockers[index];
        
        uint256 remainder = locker.cap.sub(locker.released); 
	uint256 resolutionFee = remainder.div(locker.resolutionRate); // calculate dispute resolution fee
	    
	require(locker.locked == 1, "!locked"); 
	require(locker.cap > locker.released, "released");
	require(_msgSender() != locker.client, "resolver == client");
	    
	if (locker.swiftArb == 0) {
            require(_msgSender() == locker.resolver, "!resolver");
        } else {
            require(IERC20(swiftArbToken).balanceOf(_msgSender()) >= swiftArbTokenBalance, "!swiftArbTokenBalance");
        }

	for (uint256 i = 0; i < locker.provider.length; i++) {
            require(msg.sender != locker.provider[i], "resolver == provider");
            require(clientAward.add(providerAward[i]) == remainder.sub(resolutionFee), "resolution != remainder");
            IERC20(locker.token).safeTransfer(locker.provider[i], providerAward[i]);
        }
  
        IERC20(locker.token).safeTransfer(locker.client, clientAward);
        IERC20(locker.token).safeTransfer(locker.resolver, resolutionFee);
	    
	locker.released = locker.released.add(remainder); 
	    
	emit Resolve(_msgSender(), clientAward, providerAward, index, resolutionFee, resolution);
    }
    
    /**************
    LEXDAO FUNCTION
    **************/
    function updateLockerSettings(address _governor, address _swiftArbToken, uint256 _MAX_DURATION, uint256 _resolutionRate, uint256 _swiftArbTokenBalance, string calldata _lockerStamp) external { 
        require(_msgSender() == governor, "!governor");
        
        governor = _governor;
        swiftArbToken = _swiftArbToken;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftArbTokenBalance = _swiftArbTokenBalance;
        lockerStamp = _lockerStamp;
	    
	emit UpdateLockerSettings(governor, swiftArbToken, MAX_DURATION, resolutionRate, swiftArbTokenBalance, lockerStamp);
    }
    
    /**************
    GETTER FUNCTION
    **************/
    function getProviderBatch(uint256 index) external view returns (address[] memory, uint256[] memory) {
        Locker storage locker = lockers[index];
        
        return (locker.provider, locker.batch);
    }
}
