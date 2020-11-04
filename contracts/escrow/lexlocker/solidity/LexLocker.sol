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
// Please audit & use at your own risk.
/// Entry into LXL shall not create an attorney/client relationship.
//// Likewise, LXL should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W 
~presented by LexDAO LLC \+|+/ 
*/
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.4;

interface IERC20 { // brief interface for erc20 token tx
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address { // helper for address type - see openzeppelin-contracts/blob/master/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
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

contract ReentrancyGuard { // call wrapper for reentrancy check - see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract LexLocker is Context, ReentrancyGuard { // milestone token locker registry w/ ADR for digital dealing
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /*$<⚖️️> LXL <⚔️>$*/
    address public dao; // account managing LXL settings
    address public swiftResolverToken; // token required to participate as swift resolver
    address public wETH; // ether token wrapper contract reference
    uint256 public lockerCount; // lockers counted into LXL registry
    uint256 public MAX_DURATION; // time limit on token lockup - default 63113904 (2-year)
    uint256 public resolutionRate; // rate to determine resolution fee for disputed locker (e.g., 20 = 5% of remainder)
    uint256 public swiftResolverTokenBalance; // balance required in swiftResolverToken to participate as swift resolver
    string public lockerTerms; // general terms wrapping LXL
    bool public recoveryRoleRenounced; // tracks status of dao burning admin role over deposited tokens
    
    event DepositLocker(address indexed client, address clientOracle, address indexed provider, address indexed resolver, address token, uint256[] amount, uint256 registration, uint256 sum, uint256 termination, string details, bool swiftResolver);
    event RegisterLocker(address indexed client, address clientOracle, address indexed provider, address indexed resolver, address token, uint256[] amount, uint256 registration, uint256 sum, uint256 termination, string details, bool swiftResolver);
    event ConfirmLocker(uint256 indexed registration); 
    event ResolverLocker(address indexed depositor, address indexed counterparty, address indexed resolver, address token, uint256 deposit, string details, bool swiftResolver); 
    event TimeLocker(address indexed depositor, address indexed beneficiary, address token, uint256 deposit, uint256 indexed termination, string details);
    event Release(uint256 indexed milestone, uint256 indexed registration); 
    event Withdraw(uint256 indexed registration);
    event AssignClientOracle(address indexed clientOracle, uint256 indexed registration);
    event ClientProposeResolver(address indexed proposedResolver, uint256 indexed registration, string details);
    event ProviderProposeResolver(address indexed proposedResolver, uint256 indexed registration, string details);
    event Lock(address indexed caller, uint256 indexed registration, string indexed details);
    event Resolve(uint256 indexed clientAward, uint256 indexed providerAward, uint256 indexed registration, uint256 resolutionFee, string resolution); 
    event UpdateLockerSettings(address indexed dao, address indexed swiftResolverToken, address wETH, uint256 MAX_DURATION, uint256 indexed resolutionRate, uint256 swiftResolverTokenBalance, string lockerTerms);
    event RecoverTokenBalance(address indexed recipient, address indexed token, uint256 indexed amount, uint256 registration, string details);
    event RenounceRecoveryRole(string details);

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
        address provider;
        address token;
        uint8 confirmed;
        uint8 locked;
        uint256[] amount;
        uint256 lastMilestone;
        uint256 milestones;
        uint256 released;
        uint256 sum;
        uint256 termination;
        string details; 
    }
    
    mapping(uint256 => ADR) public adrs; // tracks ADR details for registered LXL
    mapping(uint256 => Locker) public lockers; // tracks registered LXL details
    
    modifier onlyDAO {
        require(_msgSender() == dao, "!dao");
        _;
    }
    
    constructor(
        address _dao, 
        address _swiftResolverToken, 
        address _wETH,
        uint256 _MAX_DURATION,
        uint256 _resolutionRate, 
        uint256 _swiftResolverTokenBalance, 
        string memory _lockerTerms
    ) {
        dao = _dao;
        swiftResolverToken = _swiftResolverToken;
        wETH = _wETH;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
    }

    /***************
    LOCKER FUNCTIONS
    ***************/
    function depositLocker( // CLIENT-TRACK: register locker w/ token deposit & provider deal confirmation via performance
        address clientOracle, // client can set additional account to manage release of milestone amounts
        address provider,
        address resolver,
        address token,
        uint256[] memory amount, 
        uint256 termination, // exact termination date in seconds since epoch
        string memory details,
        bool swiftResolver // allow swiftResolverToken balance holder to resolve
    ) external nonReentrant payable returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < amount.length; i++) {
            sum = sum.add(amount[i]);
        }
 
        require(termination <= block.timestamp.add(MAX_DURATION), "duration maxed");
        
        if (msg.value > 0) {
            require(token == wETH && msg.value == sum, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), sum);
        }
        
        lockerCount++;
        uint256 registration = lockerCount;
        
        adrs[registration] = ADR( 
            address(0),
            resolver,
            0,
            0,
	        resolutionRate,
	        swiftResolver);

        lockers[registration] = Locker( 
            _msgSender(), 
            clientOracle,
            provider,
            token,
            1,
            0,
            amount,
            0,
            amount.length,
            0,
            sum,
            termination,
            details);

        emit DepositLocker(_msgSender(), clientOracle, provider, resolver, token, amount, registration, sum, termination, details, swiftResolver); 
        
	    return registration;
    }
    
    function registerLocker( // PROVIDER-TRACK: register locker for token deposit & client deal confirmation
        address client,
        address clientOracle,
        address provider,
        address resolver,
        address token,
        uint256[] memory amount, 
        uint256 termination, // exact termination date in seconds since epoch
        string memory details,
        bool swiftResolver // allow swiftResolverToken balance holder to resolve
    ) external nonReentrant returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < amount.length; i++) {
            sum = sum.add(amount[i]);
        }
 
        require(termination <= block.timestamp.add(MAX_DURATION), "duration maxed");
        
        lockerCount++;
        uint256 registration = lockerCount;
       
        adrs[registration] = ADR( 
            address(0),
            resolver,
            0,
            0,
	        resolutionRate,
	        swiftResolver);

        lockers[registration] = Locker( 
            client, 
            clientOracle,
            provider,
            token,
            1,
            0,
            amount,
            0,
            amount.length,
            0,
            sum,
            termination,
            details);

        emit RegisterLocker(client, clientOracle, provider, resolver, token, amount, registration, sum, termination, details, swiftResolver); 
        
	    return registration;
    }
    
    function confirmLocker(uint256 registration) external nonReentrant payable { // PROVIDER-TRACK: client confirms deposit of cap & locks in deal
        Locker storage locker = lockers[registration];
        
        require(locker.confirmed == 0, "confirmed");
        require(_msgSender() == locker.client, "!client");
        
        address token = locker.token;
        uint256 sum = locker.sum;
        
        if (msg.value > 0) {
            require(token == wETH && msg.value == sum, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), sum);
        }
        
        locker.confirmed = 1;
        
        emit ConfirmLocker(registration); 
    }
    
    function resolverLocker( // register locker w/ token deposit for resolution (e.g., interpreting performance of agreement, occurrence of wagered event)
        address counterparty,
        address resolver,
        address token,
        uint256 deposit, 
        string memory details,
        bool swiftResolver // allow swiftResolverToken balance holder to resolve
    ) external nonReentrant payable returns (uint256) {
        if (msg.value > 0) {
            require(token == wETH && msg.value == deposit, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), deposit);
        }
        
        lockerCount++;
        uint256 registration = lockerCount;
        uint256[] memory amount = new uint256[](1);
        amount[0] = deposit;
     
        lockers[registration] = Locker( 
            _msgSender(), 
            address(0),
            counterparty,
            token,
            1,
            1,
            amount,
            0,
            1,
            0,
            deposit,
            block.timestamp.add(MAX_DURATION),
            details);

        emit ResolverLocker(_msgSender(), counterparty, resolver, token, deposit, details, swiftResolver); 
        
	    return registration;
    }
    
    function timeLocker( // register timed locker w/ token deposit for beneficiary
        address beneficiary, // account that can call withdraw after termination to claim deposited token amount
        address token,
        uint256 deposit, // sum to lock until termination
        uint256 termination, // exact termination date in seconds since epoch
        string calldata details
    ) external nonReentrant payable returns (uint256) {
        require(termination <= block.timestamp.add(MAX_DURATION), "duration maxed"); 
        
        if (msg.value > 0) {
            require(token == wETH && msg.value == deposit, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), deposit);
        }
        
        lockerCount++;
        uint256 registration = lockerCount;
        uint256[] memory amount = new uint256[](1);
        amount[0] = deposit;
       
        lockers[registration] = Locker( 
            beneficiary, 
            address(0),
            address(0),
            token,
            1,
            0,
            amount,
            0,
            1,
            0,
            deposit,
            termination,
            details);

        emit TimeLocker(_msgSender(), beneficiary, token, deposit, termination, details); 
        
	    return registration;
    }
    
    function release(uint256 registration) external nonReentrant { // client or oracle can release milestone payment to provider 
    	Locker storage locker = lockers[registration];
	    
	    require(locker.confirmed == 1, "!confirmed");
	    require(locker.locked == 0, "locked");
	    require(locker.sum > locker.released, "released");
	    require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        
        uint256 milestone = locker.lastMilestone;
        uint256 payment = locker.amount[milestone];
        locker.lastMilestone++;
        
        IERC20(locker.token).safeTransfer(locker.provider, payment);
        locker.released = locker.released.add(payment);

	    emit Release(milestone, registration); 
    }
    
    function withdraw(uint256 registration) external nonReentrant { // withdraw locker remainder to client if termination time passes & no lock
    	Locker storage locker = lockers[registration];
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.locked == 0, "locked");
        require(locker.sum > locker.released, "released");
        require(block.timestamp > locker.termination, "!terminated");
        require(_msgSender() == locker.client || _msgSender() == locker.clientOracle, "!client/oracle");
        
        uint256 remainder = locker.sum.sub(locker.released); 
        
        IERC20(locker.token).safeTransfer(locker.client, remainder);
        
        locker.released = locker.sum; 
        
	    emit Withdraw(registration); 
    }
    
    // ***************
    // CLIENT FUNCTION
    // ***************
    function assignClientOracle(address clientOracle, uint256 registration) external nonReentrant {
        Locker storage locker = lockers[registration];
        
        require(_msgSender() == locker.client, "!client");
        
        locker.clientOracle = clientOracle;
        
        emit AssignClientOracle(clientOracle, registration);
    }
    
    // ***************
    // GETTER FUNCTION
    // ***************
    function getProviderAmount(uint256 registration) external view returns (address, uint256[] memory) {
        Locker storage locker = lockers[registration];
        
        return (locker.provider, locker.amount);
    }
    
    /************
    ADR FUNCTIONS
    ************/
    function lock(uint256 registration, string calldata details) external nonReentrant { // client or provider can lock remainder for resolution during locker period / update request details
        Locker storage locker = lockers[registration]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(locker.sum > locker.released, "released");
        require(block.timestamp < locker.termination, "terminated"); 
        require(_msgSender() == locker.client || _msgSender() == locker.provider, "!party"); 

	    locker.locked = 1; 
	    
	    emit Lock(_msgSender(), registration, details);
    }
    
    function resolve(uint256 registration, uint256 clientAward, uint256 providerAward, string calldata resolution) external nonReentrant { // resolver splits locked deposit remainder between client & provider
        ADR storage adr = adrs[registration];
        Locker storage locker = lockers[registration];
        
        uint256 remainder = locker.sum.sub(locker.released); 
	    uint256 resolutionFee = remainder.div(adr.resolutionRate); // calculate dispute resolution fee
	    
	    require(locker.locked == 1, "!locked"); 
	    require(locker.sum > locker.released, "released");
	    require(_msgSender() != locker.client && _msgSender() != locker.clientOracle && _msgSender() != locker.provider, "resolver == client/clientOracle/provider");
	    
	    if (!adr.swiftResolver) {
            require(_msgSender() == adr.resolver, "!resolver");
        } else {
            require(IERC20(swiftResolverToken).balanceOf(_msgSender()) >= swiftResolverTokenBalance, "!swiftResolverTokenBalance");
        }

        require(clientAward.add(providerAward) == remainder.sub(resolutionFee), "resolution != remainder");
        
        IERC20(locker.token).safeTransfer(locker.provider, providerAward);
        IERC20(locker.token).safeTransfer(locker.client, clientAward);
        IERC20(locker.token).safeTransfer(adr.resolver, resolutionFee);
	    
	    locker.released = locker.sum; 
	    
	    emit Resolve(clientAward, providerAward, registration, resolutionFee, resolution);
    }
    
    function clientProposeResolver(address proposedResolver, uint256 registration, string calldata details) external nonReentrant { // client & main (0) provider can update resolver selection
        ADR storage adr = adrs[registration];
        Locker storage locker = lockers[registration]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(adr.clientProposedResolver == 0, "pending");
	    require(locker.sum > locker.released, "released");
        require(_msgSender() == locker.client, "!client"); 
        
        if (adr.proposedResolver == proposedResolver) {
            adr.resolver = proposedResolver;
        } else {
            adr.clientProposedResolver = 0;
            adr.providerProposedResolver = 0;
        }

	    adr.proposedResolver = proposedResolver; 
	    adr.clientProposedResolver = 1;
	    
	    emit ClientProposeResolver(proposedResolver, registration, details);
    }
    
    function providerProposeResolver(address proposedResolver, uint256 registration, string calldata details) external nonReentrant { // client & main (0) provider can update resolver selection
        ADR storage adr = adrs[registration];
        Locker storage locker = lockers[registration]; 
        
        require(locker.confirmed == 1, "!confirmed");
        require(adr.providerProposedResolver == 0, "pending");
	    require(locker.sum > locker.released, "released");
        require(_msgSender() == locker.provider, "!provider"); 

	    if (adr.proposedResolver == proposedResolver) {
            adr.resolver = proposedResolver;
        } else {
            adr.clientProposedResolver = 0;
            adr.providerProposedResolver = 0;
        }
	    
	    adr.proposedResolver = proposedResolver;
	    adr.providerProposedResolver = 1;
	    
	    emit ProviderProposeResolver(proposedResolver, registration, details);
    }
   
    /***************
    GOVERN FUNCTIONS
    ***************/
    function recoverTokenBalance(
        address recipient, 
        address token, 
        uint256 amount, 
        uint256 registration, 
        string calldata details
    ) external nonReentrant onlyDAO { 
	    require(!recoveryRoleRenounced, "!recoveryRoleActive");
	
	    if (registration != 0) {
            Locker storage locker = lockers[registration];
	        require(amount == locker.sum.sub(locker.released), "!remainder");
	        locker.released = locker.sum;
        } 
	
	    IERC20(token).safeTransfer(recipient, amount);
       
	    emit RecoverTokenBalance(recipient, token, amount, registration, details);
    }
    
    function renounceRecoveryRole(string calldata details) external onlyDAO { 
	    recoveryRoleRenounced = true;
    
	    emit RenounceRecoveryRole(details);
    }
    
    function updateLockerSettings(
    	address _dao, 
	    address _swiftResolverToken,
	    address _wETH,
	    uint256 _MAX_DURATION, 
	    uint256 _resolutionRate, 
	    uint256 _swiftResolverTokenBalance, 
	    string calldata _lockerTerms
    ) external nonReentrant onlyDAO { 
        dao = _dao;
        swiftResolverToken = _swiftResolverToken;
        wETH = _wETH;
        MAX_DURATION = _MAX_DURATION;
        resolutionRate = _resolutionRate;
        swiftResolverTokenBalance = _swiftResolverTokenBalance;
        lockerTerms = _lockerTerms;
	    
	    emit UpdateLockerSettings(_dao, _swiftResolverToken, _wETH, _MAX_DURATION, _resolutionRate, _swiftResolverTokenBalance, _lockerTerms);
    }
}
