pragma solidity 0.8.0;

interface IERC20 { // brief interface for moloch erc20 token txs
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract DepositLocker {
    address public ETH_TOKEN = address(0);
    uint256 public lockerCount;
    
    mapping(uint256 => Locker) public lockers;
    
    event DepositLocker(address sender, address receiver, address token, uint256 amount, uint256 registration);
    event ReleaseLocker(uint256 registration);
    
    struct Locker {  
        address sender;
        address receiver;
        address token;
        uint256 amount;
    }
    
    receive() payable external {}
    
    function depositLocker(address receiver, address token, uint256 amount) external payable {
        if (token == ETH_TOKEN) {
            (bool success, ) = address(this).call{value: amount}("");
            require(success, "withdraw failed");
        } else {
            IERC20 erc20 = IERC20(token);
            erc20.transferFrom(msg.sender, address(this), amount);
        }
        
        lockerCount++;
        uint256 registration = lockerCount;

        lockers[registration] = Locker(msg.sender, receiver, token, amount);
        
        emit DepositLocker(msg.sender, receiver, token, amount, registration);
    }
    
    function releaseLocker(uint256 registration) external {
        require(msg.sender == lockers[registration].sender);
        
        if (lockers[registration].token == ETH_TOKEN) {
            (bool success, ) = lockers[registration].receiver.call{value: lockers[registration].amount}("");
            require(success, "withdraw failed");
        } else {
            IERC20 erc20 = IERC20(lockers[registration].token);
            erc20.transfer(lockers[registration].receiver, lockers[registration].amount);
        }
        
        emit ReleaseLocker(registration);
    }
}
