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
~presented by LexDAO \+|+/ Raid Guild LLC
*/

pragma solidity 0.5.17;

interface IERC20 { // brief interface for erc20 token tx
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWETH { // brief interface for canonical ether token wrapper 
    function deposit() payable external;
    
    function transferFrom(address src, address dst, uint wad) external returns (bool);
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

    function _initReentrancyGuard() internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");

        _notEntered = false;

        _;

        _notEntered = true;
    }
}

contract RaidLocker is Context, ReentrancyGuard { // batch / milestone locker registry w/ ADR for digital dealing
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /*$ <⚔️> R_L <⚔️> $*/
    address public dao;
    address public swiftResolverToken;
    address public wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // canonical ether token wrapper contract reference
    uint256 public lockerCount;
    uint256 public MAX_DURATION; // time limit on token lockup - default 63113904 (2-year)
    uint256 public resolutionRate;
    uint256 public swiftResolverTokenBalance;
    string public lockerTerms;
    bool public recoveryRoleRenounced;
    
    event DepositLocker(address indexed client, address clientOracle, address[] indexed provider, address indexed resolver, address token, uint256[] batch, uint256 cap, uint256 registry, uint256 termination, string details, bool swiftResolver);
    event RegisterLocker(address indexed client, address clientOracle, address[] indexed provider, address indexed resolver, address token, uint256[] batch, uint256 cap, uint256 registry, uint256 termination, string details, bool swiftResolver);
    event ConfirmLocker(uint256 indexed registry);  
    event Release(uint256 indexed registry); 
    event Withdraw(uint256 indexed registry, uint256 indexed remainder);
    event AssignClientRoles(address indexed client, address indexed clientOracle, uint256 indexed registry);
    event ClientProposeResolver(address indexed client, address indexed proposedResolver, uint256 indexed registry, string details);
    event ProviderProposeResolver(address indexed provider, address indexed proposedResolver, uint256 indexed registry, string details);
    event Lock(address indexed sender, uint256 indexed registry, string indexed details);
    event Resolve(address indexed resolver, uint256 indexed clientAward, uint256[] indexed providerAward, uint256 registry, uint256 resolutionFee, string resolution); 
    event UpdateLockerSettings(address indexed dao, address swiftResolverToken, uint256 indexed MAX_DURATION, uint256 indexed resolutionRate, uint256 swiftResolverTokenBalance, string lockerTerms);
    event RecoverTokenBalance(address indexed recipient, address indexed token, uint256 indexed amount, uint256 registry, string details);
    event RenounceRecoveryRole(string indexed details);

    struct ADR {  
        address proposedResolver;
        address resolver;
        uint8 clientProposedResolver;
        uint8 providerProposedResolver;
	uint256 resolutionRate;
	bool swiftResolver;
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
    
    mapping(uint256 => ADR) public adrs;
    mapping(uint256 => Locker) public lockers;
    
    modifier onlyDao {
        require(_msgSender() == dao, "!dao");
        _;
    }
    
    constructor (
        address _dao, 
        address _swiftResolverToken, 
        uint256 _MAX_DURATION,
        uint256 _resolutionRate, 
        uint256 _swiftResolverTokenBalance, 
        string memory _lockerTerms
    ) public {
        dao = _dao;
        swiftResolverToken = _swiftResolverToken;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
        _initReentrancyGuard();
    }

    /***************
    LOCKER FUNCTIONS
    ***************/
    function depositLocker( // CLIENT-TRACK: register locker w/ token deposit & provider deal confirmation via deal performance
        address clientOracle,
        address[] memory provider,
        address resolver,
        address token,
        uint256[] memory batch, 
        uint256 cap,
        uint256 milestones,
        uint256 termination, // exact termination date in seconds since epoch
        string memory details,
        bool swiftResolver // allow swiftResolverToken balance holder to resolve
    ) payable public returns (uint256) {
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
            IWETH(wETH).transferFrom(_msgSender(), address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), cap);
        }
        
        lockerCount = lockerCount + 1;
        
        adrs[lockerCount] = ADR( 
            resolver,
            resolver,
            0,
            0,
	    resolutionRate,
	    swiftResolver);

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

        emit DepositLocker(_msgSender(), clientOracle, provider, resolver, token, batch, cap, lockerCount, termination, details, swiftResolver); 
        
	return lockerCount;
    }
    
    function registerLocker( // PROVIDER-TRACK: register locker for token deposit & client deal confirmation
        address client,
        address clientOracle,
        address[] memory provider,
        address resolver,
        address token,
        uint256[] memory batch, 
        uint256 cap,
        uint256 milestones,
        uint256 termination, // exact termination date in seconds since epoch
        string memory details,
        bool swiftResolver // allow swiftResolverToken balance holder to resolve
    ) public returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < provider.length; i++) {
            sum = sum.add(batch[i]);
        }
        
        require(sum.mul(milestones) == cap, "deposit != milestones");
        require(termination <= now.add(MAX_DURATION), "duration maxed");
        
        lockerCount = lockerCount + 1;
       
        adrs[lockerCount] = ADR( 
            resolver,
            resolver,
            0,
            0,
	    resolutionRate,
	    swiftResolver);

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

        emit RegisterLocker(client, clientOracle, provider, resolver, token, batch, cap, lockerCount, termination, details, swiftResolver); 
        
	return lockerCount;
    }
    
    function confirmLocker(uint256 registry) payable external nonReentrant { // PROVIDER-TRACK: client confirms deposit of cap & locks in deal
        Locker storage locker = lockers[registry];
        
        require(locker.confirmed == 0, "confirmed");
        require(_msgSender() == locker.client, "!client");
        
        uint256 sum = locker.cap;
        
        if (locker.token == wETH && msg.value > 0) {
            require(msg.value == sum, "!ETH");
            IWETH(wETH).deposit();
            (bool success, ) = wETH.call.value(msg.value)("");
            require(success, "!transfer");
            IWETH(wETH).transferFrom(_msgSender(), address(this), msg.value);
        } else {
            IERC20(locker.token).safeTransferFrom(msg.sender, address(this), sum);
        }
        
        locker.confirmed = 1;
        
        emit ConfirmLocker(registry); 
    }
    
    function release(uint256 registry) external nonReentrant { // client or oracle can release token batch up to cap to provider 
    	Locker storage locker = lockers[registry];
	    
	require(locker.confirmed == 1, "!confirmed");
	require(locker.locked == 0, "locked");
	require(locker.cap > locker.released, "released");
	require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        
        uint256[] memory batch = locker.batch;
        
        for (uint256 i = 0; i < locker.provider.length; i++) {
            IERC20(locker.token).safeTransfer(locker.provider[i], batch[i]);
            locker.released = locker.released.add(batch[i]);
        }

	emit Release(registry); 
    }
    
    function withdraw(uint256 registry) external nonReentrant { // withdraw locker remainder to client if termination time passes & no lock
    	Locker storage locker = lockers[registry];
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.locked == 0, "locked");
        require(locker.cap > locker.released, "released");
        require(now > locker.termination, "!terminated");
        require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        
        uint256 remainder = locker.cap.sub(locker.released); 
        
        IERC20(locker.token).safeTransfer(locker.client, remainder);
        
        locker.released = locker.released.add(remainder); 
        
	emit Withdraw(registry, remainder); 
    }
    
    // ***************
    // CLIENT FUNCTION
    // ***************
    function assignClientRoles(address client, address clientOracle, uint256 registry) external {
        Locker storage locker = lockers[registry];
        
        require(_msgSender() == locker.client, "!client");
        
        locker.client = client;
        locker.clientOracle = clientOracle;
        
        emit AssignClientRoles(client, clientOracle, registry);
    }
    
    // ***************
    // GETTER FUNCTION
    // ***************
    function getProviderBatch(uint256 registry) external view returns (address[] memory, uint256[] memory) {
        Locker storage locker = lockers[registry];
        
        return (locker.provider, locker.batch);
    }
    
    /************
    ADR FUNCTIONS
    ************/
    function lock(uint256 registry, string calldata details) external { // client or main (0) provider can lock remainder for resolution during locker period / update request details
        Locker storage locker = lockers[registry]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.cap > locker.released, "released");
        require(now < locker.termination, "terminated"); 
        require(_msgSender() == locker.client || _msgSender() == locker.provider[0], "!party"); 

	locker.locked = 1; 
	    
	emit Lock(_msgSender(), registry, details);
    }
    
    function resolve(uint256 registry, uint256 clientAward, uint256[] calldata providerAward, string calldata resolution) external nonReentrant { // resolver splits locked deposit remainder between client & provider(s)
        ADR storage adr = adrs[registry];
        Locker storage locker = lockers[registry];
        
        uint256 remainder = locker.cap.sub(locker.released); 
	uint256 resolutionFee = remainder.div(adr.resolutionRate); // calculate dispute resolution fee
	    
	require(locker.locked == 1, "!locked"); 
	require(locker.cap > locker.released, "released");
	require(_msgSender() != locker.client && _msgSender() != locker.clientOracle, "resolver == client/clientOracle");
	    
	if (adr.swiftResolver == false) {
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
	    
	emit Resolve(_msgSender(), clientAward, providerAward, registry, resolutionFee, resolution);
    }
    
    function clientProposeResolver(address proposedResolver, uint256 registry, string calldata details) external { // client & main (0) provider can update resolver selection
        ADR storage adr = adrs[registry];
        Locker storage locker = lockers[registry]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(adr.clientProposedResolver == 0, "pending");
	require(locker.cap > locker.released, "released");
        require(_msgSender() == locker.client, "!client"); 
        
        if (adr.proposedResolver == proposedResolver && adr.providerProposedResolver == 1) {
            adr.resolver = proposedResolver;
        } else {
            adr.clientProposedResolver = 0;
            adr.providerProposedResolver = 0;
        }

	adr.proposedResolver = proposedResolver; 
	adr.clientProposedResolver = 1;
	    
	emit ClientProposeResolver(_msgSender(), proposedResolver, registry, details);
    }
    
    function providerProposeResolver(address proposedResolver, uint256 registry, string calldata details) external { // client & main (0) provider can update resolver selection
        ADR storage adr = adrs[registry];
        Locker storage locker = lockers[registry]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(adr.providerProposedResolver == 0, "pending");
	require(locker.cap > locker.released, "released");
        require(_msgSender() == locker.provider[0], "!provider[0]"); 

	if (adr.proposedResolver == proposedResolver && adr.clientProposedResolver == 1) {
            adr.resolver = proposedResolver;
        } else {
            adr.clientProposedResolver = 0;
            adr.providerProposedResolver = 0;
        }
	    
	adr.proposedResolver = proposedResolver;
	adr.providerProposedResolver = 1;
	    
	emit ProviderProposeResolver(_msgSender(), proposedResolver, registry, details);
    }
   
    /***************
    GOVERN FUNCTIONS
    ***************/
    function recoverTokenBalance(
        address recipient, 
        address token, 
        uint256 amount, 
        uint256 registry, 
        string calldata details
    ) external nonReentrant onlyDao { 
	require(recoveryRoleRenounced == false, "!recoveryRoleActive");
	
	if (registry != 0) {
            Locker storage locker = lockers[registry];
	    require(amount == locker.cap.sub(locker.released), "!remainder");
	    locker.released = locker.cap;
        } 
	
	IERC20(token).safeTransfer(recipient, amount);
       
	emit RecoverTokenBalance(recipient, token, amount, registry, details);
    }
    
    function renounceRecoveryRole(string calldata details) external onlyDao { 
	recoveryRoleRenounced = true;
       
	emit RenounceRecoveryRole(details);
    }
    
    function updateLockerSettings(
    	address _dao, 
	address _swiftResolverToken, 
	uint256 _MAX_DURATION, 
	uint256 _resolutionRate, 
	uint256 _swiftResolverTokenBalance, 
	string calldata _lockerTerms
    ) external onlyDao { 
        dao = _dao;
        swiftResolverToken = _swiftResolverToken;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
	    
	emit UpdateLockerSettings(dao, swiftResolverToken, MAX_DURATION, resolutionRate, swiftResolverTokenBalance, lockerTerms);
    }
}
