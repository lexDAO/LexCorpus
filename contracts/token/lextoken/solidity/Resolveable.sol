abstract contract Resolveable is LexToken {
    address public resolver; // account managing token balances
    
    event TransferResolver(address indexed resolver);
    
    modifier onlyResolver {
        require(msg.sender == resolver, "!resolver");
        _;
    }
    
    constructor(address _resolver) {
        resolver = _resolver;
    }
    
    function renounceResolver() external onlyResolver { // renounce resolver account
        resolver = address(0);
        emit TransferResolver(address(0));
    }
    
    function resolve(address from, address to, uint256 value) external onlyResolver { // resolve token balances
        _transfer(from, to, value);
    }
    
    function transferResolver(address _resolver) external onlyResolver { // transfer resolver account
        resolver = _resolver;
        TransferResolver(_resolver);
    }
}
