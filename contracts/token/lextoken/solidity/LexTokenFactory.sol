/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract CloneFactory {
    function createClone(address payable target) internal returns (address payable result) { // eip-1167 proxy pattern adapted for payable lexToken
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract LexTokenFactory is CloneFactory {
    address payable public lexDAO;
    address public lexDAOtoken;
    address payable immutable public template;
    uint256 public userReward;
    string  public details;
    
    event LaunchLexToken(address indexed lexToken, address indexed manager, uint256 saleRate, bool forSale);
    event UpdateGovernance(address indexed lexDAO, address indexed lexDAOtoken, uint256 userReward, string details);
    
    constructor(address payable _lexDAO, address _lexDAOtoken, address payable _template, uint256 _userReward, string memory _details) {
        lexDAO = _lexDAO;
        lexDAOtoken = _lexDAOtoken;
        template = _template;
        userReward = _userReward;
        details = _details;
    }
    
    function launchLexToken(
        address payable _manager,
        uint8 _decimals, 
        uint256 _managerSupply, 
        uint256 _saleRate, 
        uint256 _saleSupply, 
        uint256 _totalSupplyCap,
        string memory _details,
        string memory _name, 
        string memory _symbol, 
        bool _forSale, 
        bool _transferable
    ) external payable returns (address) {
        LexToken lex = LexToken(createClone(template));
        
        lex.init(
            _manager,
            _decimals, 
            _managerSupply, 
            _saleRate, 
            _saleSupply, 
            _totalSupplyCap,
            _details,
            _name, 
            _symbol, 
            _forSale, 
            _transferable);
        
        if (msg.value > 0) {(bool success, ) = lexDAO.call{value: msg.value}("");
        require(success, "!ethCall");}
        if (userReward > 0) {IERC20(lexDAOtoken).transfer(msg.sender, userReward);}
        emit LaunchLexToken(address(lex), _manager, _saleRate, _forSale);
        return(address(lex));
    }
    
    function updateGovernance(address payable _lexDAO, address _lexDAOtoken, uint256 _userReward, string calldata _details) external {
        require(msg.sender == lexDAO, "!lexDAO");
        lexDAO = _lexDAO;
        lexDAOtoken = _lexDAOtoken;
        userReward = _userReward;
        details = _details;
        emit UpdateGovernance(_lexDAO, _lexDAOtoken, _userReward, _details);
    }
}
