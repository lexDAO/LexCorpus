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
/ R_L is a project in beta.
// Please audit & use at your own risk.
/// Entry into R_L shall not create an attorney/client relationship.
//// Likewise, R_L should not be construed as legal advice or replacement for professional counsel.
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

contract Context { // describe current contract execution context (metaTX support) - see openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
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

    /*$ <⚔️> R_L <⚔️> $*/
    address public governor;
    address public swiftResolverToken;
    address public wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // canonical ether token wrapper contract reference
    uint256 public lockerCount;
    uint256 public MAX_DURATION; // time limit on token lockup - default 63113904 (2-year)
    uint256 public resolutionRate;
    uint256 public swiftResolverTokenBalance;
    string public lockerTerms;
    bool public recoveryRoleRenounced;
    
    event DepositLocker(address indexed client, address clientOracle, address[] indexed provider, address indexed resolver, address token, uint8 swiftResolver, uint256[] batch, uint256 cap, uint256 index, uint256 termination, string details);
    event RegisterLocker(address indexed client, address clientOracle, address[] indexed provider, address indexed resolver, address token, uint8 swiftResolver, uint256[] batch, uint256 cap, uint256 index, uint256 termination, string details);
    event ConfirmLocker(uint256 indexed index, uint256 indexed sum);  
    event Release(uint256 indexed index, uint256[] indexed milestone); 
    event Withdraw(uint256 indexed index, uint256 indexed remainder);
    event AssignClientRoles(address indexed client, address indexed clientOracle, uint256 indexed index);
    event ClientUpdateResolver(address indexed client, address indexed updatedResolver, uint256 indexed index, string details);
    event ProviderUpdateResolver(address indexed provider, address indexed updatedResolver, uint256 indexed index, string details);
    event Lock(address indexed sender, uint256 indexed index, string indexed details);
    event Resolve(address indexed resolver, uint256 indexed clientAward, uint256[] indexed providerAward, uint256 index, uint256 resolutionFee, string resolution); 
    event UpdateLockerSettings(address indexed governor, address swiftResolverToken, uint256 indexed MAX_DURATION, uint256 indexed resolutionRate, uint256 swiftResolverTokenBalance, string lockerTerms);
    event RecoverTokenBalance(address indexed governor, address indexed recipient, address token, uint256 indexed amount, uint256 index, string details);
    event RenounceRecoveryRole(address indexed governor, string indexed details);

    struct ADR {  
        address resolver;
        address updatedResolver;
        uint8 clientUpdateResolver;
        uint8 providerUpdateResolver;
        uint8 swiftResolver;
	uint256 resolutionRate;
    }
    
    struct Locker {  
        address client; 
        address clientOracle;
        address[] provider;
        address token;
        uint8 confirmed;
        uint8 locked;
        uint256[] batch;
        uint256 cap;
        uint256 released;
        uint256 termination;
        string details; 
    }
    
    mapping(uint256 => ADR) public resolvers;
    mapping(uint256 => Locker) public lockers;
    
    modifier onlyGovernor {
        require(_msgSender() == governor, "!governor");
        _;
    }
    
    constructor (address _governor, address _swiftResolverToken, uint256 _swiftResolverTokenBalance, uint256 _MAX_DURATION, uint256 _resolutionRate, string memory _lockerTerms) public {
        governor = _governor;
        swiftResolverToken = _swiftResolverToken;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        lockerTerms = _lockerTerms;
    }

    /***************
    LOCKER FUNCTIONS
    ***************/
    function depositLocker( // CLIENT-TRACK: register locker w/ token deposit & provider deal confirmation via deal performance
        address clientOracle,
        address[] memory provider,
        address resolver,
        address token,
        uint8 swiftResolver, // allow swiftResolverToken balance holder to resolve
        uint256[] memory batch, 
        uint256 cap,
        uint256 milestones,
        uint256 termination, // exact termination date in seconds since epoch
        string memory details) payable public returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < provider.length; i++) {
            sum = sum.add(batch[i]);
        }
        
        require(swiftResolver <= 1, "swiftResolver!");
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
        
        resolvers[lockerCount] = ADR( 
            resolver,
            resolver,
            0,
            0,
            swiftResolver,
	    resolutionRate);

        lockers[lockerCount] = Locker( 
            _msgSender(), 
            clientOracle,
            provider,
            token,
            1,
            0,
            batch,
            cap,
            0,
            termination,
            details);

        emit DepositLocker(_msgSender(), clientOracle, provider, resolver, token, swiftResolver, batch, cap, lockerCount, termination, details); 
        
	return lockerCount;
    }
    
    function registerLocker( // PROVIDER-TRACK: register locker for token deposit & client deal confirmation
        address client,
        address clientOracle,
        address[] memory provider,
        address resolver,
        address token,
        uint8 swiftResolver, // allow swiftResolverToken balance holder to resolve
        uint256[] memory batch, 
        uint256 cap,
        uint256 milestones,
        uint256 termination, // exact termination date in seconds since epoch
        string memory details) public returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < provider.length; i++) {
            sum = sum.add(batch[i]);
        }
        
        require(swiftResolver <= 1, "swiftResolver!");
        require(sum.mul(milestones) == cap, "deposit != milestones");
        require(termination <= now.add(MAX_DURATION), "duration maxed");
        
        lockerCount = lockerCount + 1;
       
        resolvers[lockerCount] = ADR( 
            resolver,
            resolver,
            0,
            0,
            swiftResolver,
	    resolutionRate);

        lockers[lockerCount] = Locker( 
            _msgSender(), 
            clientOracle,
            provider,
            token,
            0,
            0,
            batch,
            cap,
            0,
            termination,
            details);

        emit RegisterLocker(client, clientOracle, provider, resolver, token, swiftResolver, batch, cap, lockerCount, termination, details); 
        
	return lockerCount;
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
    
    function release(uint256 index) external nonReentrant { // client or oracle can release token batch up to cap to provider 
    	Locker storage locker = lockers[index];
	    
	require(locker.confirmed == 1, "!confirmed");
	require(locker.locked == 0, "locked");
	require(locker.cap > locker.released, "released");
	require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        
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
        require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        
        uint256 remainder = locker.cap.sub(locker.released); 
        
        IERC20(locker.token).safeTransfer(locker.client, remainder);
        
        locker.released = locker.released.add(remainder); 
        
	emit Withdraw(index, remainder); 
    }
    
    // ***************
    // CLIENT FUNCTION
    // ***************
    function assignClientRoles(address client, address clientOracle, uint256 index) external {
        Locker storage locker = lockers[index];
        
        require(_msgSender() == locker.client, "!client");
        
        locker.client = client;
        locker.clientOracle = clientOracle;
        
        emit AssignClientRoles(client, clientOracle, index);
    }
    
    // ***************
    // GETTER FUNCTION
    // ***************
    function getProviderBatch(uint256 index) external view returns (address[] memory, uint256[] memory) {
        Locker storage locker = lockers[index];
        
        return (locker.provider, locker.batch);
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
        ADR storage adr = resolvers[index];
        Locker storage locker = lockers[index];
        
        uint256 remainder = locker.cap.sub(locker.released); 
	uint256 resolutionFee = remainder.div(adr.resolutionRate); // calculate dispute resolution fee
	    
	require(locker.locked == 1, "!locked"); 
	require(locker.cap > locker.released, "released");
	require(_msgSender() != locker.client && _msgSender() != locker.clientOracle, "resolver == client/clientOracle");
	    
	if (adr.swiftResolver == 0) {
            require(_msgSender() == adr.resolver, "!resolver");
        } else {
            require(IERC20(swiftResolverToken).balanceOf(_msgSender()) >= swiftResolverTokenBalance, "!swiftResolverTokenBalance");
        }

	for (uint256 i = 0; i < locker.provider.length; i++) {
            require(_msgSender() != locker.provider[i], "resolver == provider");
            require(clientAward.add(providerAward[i]) == remainder.sub(resolutionFee), "resolution != remainder");
            IERC20(locker.token).safeTransfer(locker.provider[i], providerAward[i]);
        }
  
        IERC20(locker.token).safeTransfer(locker.client, clientAward);
        IERC20(locker.token).safeTransfer(adr.resolver, resolutionFee);
	    
	locker.released = locker.cap; 
	    
	emit Resolve(_msgSender(), clientAward, providerAward, index, resolutionFee, resolution);
    }
    
    function clientUpdateResolver(address updatedResolver, uint256 index, string calldata details) external { // client & main (0) provider can update resolver selection
        ADR storage adr = resolvers[index];
        Locker storage locker = lockers[index]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(adr.clientUpdateResolver == 0, "pending");
	require(locker.cap > locker.released, "released");
        require(_msgSender() == locker.client, "!client"); 
        
        if (adr.updatedResolver == updatedResolver && adr.providerUpdateResolver == 1) {
            adr.resolver = updatedResolver;
        } else {
            adr.clientUpdateResolver = 0;
            adr.providerUpdateResolver = 0;
        }

	adr.updatedResolver = updatedResolver; 
	adr.clientUpdateResolver = 1;
	    
	emit ClientUpdateResolver(_msgSender(), updatedResolver, index, details);
    }
    
    function providerUpdateResolver(address updatedResolver, uint256 index, string calldata details) external { // client & main (0) provider can update resolver selection
        ADR storage adr = resolvers[index];
        Locker storage locker = lockers[index]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(adr.providerUpdateResolver == 0, "pending");
	require(locker.cap > locker.released, "released");
        require(_msgSender() == locker.provider[0], "!provider[0]"); 

	if (adr.updatedResolver == updatedResolver && adr.clientUpdateResolver == 1) {
            adr.resolver = updatedResolver;
        } else {
            adr.clientUpdateResolver = 0;
            adr.providerUpdateResolver = 0;
        }
	    
	adr.updatedResolver = updatedResolver;
	adr.providerUpdateResolver = 1;
	    
	emit ProviderUpdateResolver(_msgSender(), updatedResolver, index, details);
    }
   
    /***************
    GOVERN FUNCTIONS
    ***************/
    function recoverTokenBalance(
        address recipient, 
        address token, 
        uint256 amount, 
        uint256 index, 
        string calldata details
    ) external nonReentrant onlyGovernor { 
	require(recoveryRoleRenounced == false, "!recoveryRoleActive");
	
	if (index != 0) {
            Locker storage locker = lockers[index];
	    require(amount == locker.cap.sub(locker.released), "!remainder");
	    locker.released = locker.cap;
        } 
	
	IERC20(token).safeTransfer(recipient, amount);
       
	emit RecoverTokenBalance(_msgSender(), recipient, token, amount, index, details);
    }
    
    function renounceRecoveryRole(string calldata details) external onlyGovernor { 
	recoveryRoleRenounced = true;
       
	emit RenounceRecoveryRole(_msgSender(), details);
    }
    
    function updateLockerSettings(
    	address _governor, 
	address _swiftResolverToken, 
	uint256 _MAX_DURATION, 
	uint256 _resolutionRate, 
	uint256 _swiftResolverTokenBalance, 
	string calldata _lockerTerms
    ) external onlyGovernor { 
        governor = _governor;
        swiftResolverToken = _swiftResolverToken;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
	    
	emit UpdateLockerSettings(governor, swiftResolverToken, MAX_DURATION, resolutionRate, swiftResolverTokenBalance, lockerTerms);
    }
}
