pragma solidity 0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IMoloch { // brief interface for txs to Moloch DAO
    function cancelProposal(uint256 proposalId) external;
    
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);
    
    function withdrawBalance(address token, uint256 amount) external;
}

interface IWETH { // brief interface for canonical ether token wrapper 
    function deposit() payable external;
    
    function transfer(address dst, uint wad) external returns (bool);
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MolochZap is Ownable {
    using SafeMath for uint256;
    address public moloch;
    address public constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // canonical ether token wrapper contract reference for proposals
    uint256 public zapCount;
    uint256 public zapRate;

    mapping (uint256 => Zap) public zaps; // proposalId => Zap
    
    struct Zap {
        address proposer;
        uint256 zapAmount;
    }

    event ProposeZap(address proposer, uint256 zapCount);
    event WithdrawZap(address proposer, uint256 molochProposalId, uint256 zapCount);

    constructor(address _moloch, uint256 _zapRate) public {
        moloch = _moloch;
        zapRate = _zapRate;
        IERC20(wETH).approve(moloch, uint256(-1));
    }

    function() payable external {
        uint256 sharesRequested = msg.value.mul(zapRate); 
        
        IWETH(wETH).deposit();
        (bool success, ) = wETH.call.value(msg.value)("");
        require(success, "!transfer");
        IWETH(wETH).transfer(address(this), msg.value);
        
        zapCount = zapCount + 1;

        IMoloch(moloch).submitProposal(
            _msgSender(),
            sharesRequested,
            0,
            msg.value,
            wETH,
            0,
            wETH,
            "MOLOCH_ZAP"
        );
        
        zaps[zapCount] = Zap(
            _msgSender(),
            msg.value);

        emit ProposeZap(_msgSender(), zapCount);
    }
    
    function updateZapRate(uint256 _zapRate) external onlyOwner {
        zapRate = _zapRate;
    }
    
    function withdrawZap(uint256 molochProposalId, uint256 _zapCount) external { // if zap proposal fails, withdraw back to proposer
        Zap storage zap = zaps[_zapCount];
        
        require(msg.sender == zap.proposer, "!proposer");
        
        bool[6] memory flags = IMoloch(moloch).getProposalFlags(molochProposalId);
        require(flags[2] == false, "MolochZap::proposal passed");
        
        IMoloch(moloch).withdrawBalance(wETH, zap.zapAmount); // withdraw funds from parent Moloch
        IERC20(wETH).transfer(zap.proposer, zap.zapAmount); // redirect funds to zap proposer
        
        emit WithdrawZap(msg.sender, molochProposalId, zapCount);
    }
}
