pragma solidity 0.5.17;

contract Boolie {
    bool public boolStuff;
    
    function doBoolStuff(bool _boolStuff) external {
        boolStuff = _boolStuff;
    }
}
