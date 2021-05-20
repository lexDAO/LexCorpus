//SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/*FOR DEMONSTRATION ONLY, not recommended to be used for any purpose and provided with no warranty whatsoever
**@dev create a simple smart escrow contract, with ETH as payment, expiration denominated in seconds, and option for dispute resolution with LexLocker
**intended to be deployed by buyer (as funds are placed in escrow upon deployment, and returned to deployer if expired),  
**from: https://github.com/ErichDylus/Aviation/edit/master/contracts/EscrowETH.sol*/

interface LexLocker {
    function requestLockerResolution(address counterparty, address resolver, address token, uint256 sum, string calldata details, bool swiftResolver) external payable returns (uint256);
}

contract EscrowEth {
    
  //escrow struct to contain basic description of underlying deal, purchase price, ultimate recipient of funds
  struct InEscrow {
      string description;
      uint256 deposit;
      address payable seller;
  }
  
  InEscrow[] public escrows;
  address escrowAddress = address(this);
  address payable lexlocker = payable(0xD476595aa1737F5FdBfE9C8FEa17737679D9f89a); //LexLocker contract address
  address payable lexDAO = payable(0x01B92E2C0D06325089c6Fd53C98a214f5C75B2aC); //lexDAO address, used below as resolver 
  address payable buyer;
  address payable seller;
  uint256 deposit;
  uint256 effectiveTime;
  uint256 expirationTime;
  bool sellerApproved;
  bool buyerApproved;
  bool isDisputed;
  bool isExpired;
  bool isClosed;
  string description;
  mapping(address => bool) public parties; //map whether an address is a party to the transaction for restricted() modifier 
  
  event DealDisputed(address indexed sender, bool isDisputed);
  event DealExpired(bool isExpired);
  event DealClosed(bool isClosed);
  
  modifier restricted() { //restricts to agent (creator of escrow contract) or internal calls
    require(parties[msg.sender], "This may only be called by a party to the deal or the escrow contract itself");
    _;
  }
  
  //creator contributes deposit and initiates escrow with description, deposit amount, and designate recipient seller
  constructor(string memory _description, uint256 _deposit, address payable _seller, uint256 _secsUntilExpiration) payable {
      require(msg.value >= deposit, "Submit deposit amount");
      require(_seller != msg.sender, "Designate different party as seller");
      buyer = payable(address(msg.sender));
      deposit = _deposit;
      description = _description;
      seller = _seller;
      parties[msg.sender] = true;
      parties[_seller] = true;
      parties[escrowAddress] = true;
      effectiveTime = uint256(block.timestamp);
      expirationTime = effectiveTime + _secsUntilExpiration;
      sendEscrow(description, deposit, seller);
  }
  
  //buyer may confirm seller's recipient address as extra security measure
  function designateSeller(address payable _seller) public restricted {
      require(_seller != seller, "Party already designated as seller");
      require(_seller != buyer, "Buyer cannot also be seller");
      require(!isExpired, "Too late to change seller");
      parties[_seller] = true;
      seller = _seller;
  }
  
  //create new escrow contract within master structure
  function sendEscrow(string memory _description, uint256 _deposit, address payable _seller) private restricted {
      InEscrow memory newRequest = InEscrow({
         description: _description,
         deposit: _deposit,
         seller: _seller
      });
      escrows.push(newRequest);
  }
  
  //check if expired, and if so, return balance to buyer
  function checkIfExpired() public returns(bool){
        if (expirationTime <= uint256(block.timestamp)) {
            isExpired = true;
            buyer.transfer(escrowAddress.balance);
            emit DealExpired(isExpired);
        } else {
            isExpired = false;
        }
        return(isExpired);
    }
    
  // for early termination by either buyer or seller due to claimed breach of the other party, claiming party requests LexLocker resolution
  // deposit either returned to buyer or remitted to seller as liquidated damages
  function disputeDeal(address _token, string calldata _details, bool _singleArbiter) public restricted returns(string memory){
      require(!isClosed && !isExpired, "Too late for early termination");
      if (msg.sender == seller) {
            LexLocker(lexlocker).requestLockerResolution(buyer, lexDAO, _token, deposit, _details, _singleArbiter);
            lexlocker.transfer(escrowAddress.balance);
            isDisputed = true;
            emit DealDisputed(seller, isDisputed);
            return("Seller has initiated LexLocker dispute resolution.");
        } else if (msg.sender == buyer) {
            LexLocker(lexlocker).requestLockerResolution(seller, lexDAO, _token, deposit, _details, _singleArbiter);
            lexlocker.transfer(escrowAddress.balance); //  presumably balance only holds the deposit amount if buyer is initiating dispute
            isDisputed = true;
            emit DealDisputed(buyer, isDisputed);
            return("Buyer has initiated Lexlocker dispute resolution.");
        } else {
            return("You are neither buyer nor seller.");
        }
  }

  function readyToClose() public restricted returns(string memory){
         if (msg.sender == seller) {
            sellerApproved = true;
            return("Seller is ready to close.");
        } else if (msg.sender == buyer) {
            buyerApproved = true;
            return("Buyer is ready to close.");
        } else {
            return("You are neither buyer nor seller.");
        }
  }
    
  // check if both buyer and seller are ready to close and expiration has not been met; if so, close deal and pay seller
  function closeDeal() public returns(bool){
      require(sellerApproved && buyerApproved, "Parties are not ready to close.");
      if (expirationTime <= uint256(block.timestamp)) {
            isExpired = true;
            buyer.transfer(escrowAddress.balance);
            emit DealExpired(isExpired);
        } else {
            isClosed = true;
            seller.transfer(escrowAddress.balance);
            emit DealClosed(isClosed);
        }
        return(isClosed);
  }
}
