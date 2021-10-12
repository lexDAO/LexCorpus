const { artifacts, ethers } = require("hardhat");
const { BigNumber, utils: { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack }, } = require("ethers")
const { expect } = require("chai");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
const { ecsign } = require("ethereumjs-util");

const bentoAddress = "0xF5BCE5077908a1b7370B9ae04AdC565EBd643966";
const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

const carolPrivateKey = "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";

const PERMIT_TYPEHASH = keccak256(toUtf8Bytes("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"));
 
chai
  .use(solidity)
  .should();

const BASE_TEN = 10;

// Defaults to e18 using amount * 10^18
function getBigNumber(amount, decimals = 18) {
  return BigNumber.from(amount).mul(BigNumber.from(BASE_TEN).pow(decimals))
}

function getDomainSeparator(tokenAddress, chainId) {
  return keccak256(
      defaultAbiCoder.encode(
          ["bytes32", "uint256", "address"],
          [keccak256(toUtf8Bytes("EIP712Domain(uint256 chainId,address verifyingContract)")), chainId, tokenAddress]
      )
  )
}

function getApprovalDigest(token, approve, nonce, deadline, chainId = 1) {
  const DOMAIN_SEPARATOR = getDomainSeparator(token.address, chainId)
  const msg = defaultAbiCoder.encode(
      ["bytes32", "address", "address", "uint256", "uint256", "uint256"],
      [PERMIT_TYPEHASH, approve.owner, approve.spender, approve.value, nonce, deadline]
  )
  const pack = solidityPack(["bytes1", "bytes1", "bytes32", "bytes32"], ["0x19", "0x01", DOMAIN_SEPARATOR, keccak256(msg)])
  return keccak256(pack)
}

async function advanceBlock() {
  return ethers.provider.send("evm_mine", [])
}

async function advanceBlockTo(blockNumber) {
  for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
    await advanceBlock()
  }
}

async function increase(value) {
  await ethers.provider.send("evm_increaseTime", [value.toNumber()])
  await advanceBlock()
}

async function latest() {
  const block = await ethers.provider.getBlock("latest")
  return BigNumber.from(block.timestamp)
}

async function advanceTimeAndBlock(time) {
  await advanceTime(time)
  await advanceBlock()
}

async function advanceTime(time) {
  await ethers.provider.send("evm_increaseTime", [time])
}

const duration = {
  seconds: function (val) {
    return BigNumber.from(val)
  },
  minutes: function (val) {
    return BigNumber.from(val).mul(this.seconds("60"))
  },
  hours: function (val) {
    return BigNumber.from(val).mul(this.minutes("60"))
  },
  days: function (val) {
    return BigNumber.from(val).mul(this.hours("24"))
  },
  weeks: function (val) {
    return BigNumber.from(val).mul(this.days("7"))
  },
  years: function (val) {
    return BigNumber.from(val).mul(this.days("365"))
  },
}

describe("LexLocker", function () {
  it("Should take an ERC20 token deposit and allow release by depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.release(1);
  });
 
  it("Should take an ETH deposit and allow release by depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();
 
    // we use a token address as well to ensure nothing weird happens if user screws up
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST", { value: getBigNumber(1000) });
    await locker.release(1);
  });

  it("Should enforce ETH deposit and locker value parity", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(10000), 0, false, "TEST", { value: getBigNumber(1000) }).should.be.revertedWith("wrong msg.value");
  });

  it("Should take an ERC20 token deposit, wrap into BentoBox, and allow release by depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const bento = await ethers.getContractAt("IBentoBoxMinimal", bentoAddress);
 
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.depositBento(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, true, "TEST");
    await locker.release(1);
  });

  it("Should take an ETH deposit, wrap into BentoBox, and allow release by depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const bento = await ethers.getContractAt("IBentoBoxMinimal", bentoAddress);
 
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.depositBento(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, true, "TEST", { value: getBigNumber(1000) });
    await locker.release(1);
  });

  it("Should enforce ETH deposit and locker value parity for BentoBox", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.depositBento(receiver.address, resolver.address, token.address, getBigNumber(10000), 0, true, "TEST", { value: getBigNumber(1000) }).should.be.revertedWith("wrong msg.value");
  });

  it("Should take an ERC721 NFT deposit and allow release by depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();
 
    const NFT = await ethers.getContractFactory("TestERC721");
    const nft = await NFT.deploy("poc", "poc");
    await nft.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    await nft.approve(locker.address, 1);
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, nft.address, 1, 0, true, "TEST");
    await locker.release(1);
  });

  it("Should forbid deposit if resolver not registered", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
    
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST").should.be.revertedWith("resolver not active");
  });

  it("Should forbid BentoBox deposit if resolver not registered", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const bento = await ethers.getContractAt("IBentoBoxMinimal", bentoAddress);
 
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.depositBento(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, true, "TEST").should.be.revertedWith("resolver not active");
  });

  it("Should forbid deposit if resolver is party to locker", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
    
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(depositor).registerResolver(true, 20);
    await locker.connect(receiver).registerResolver(true, 20);
    await locker.deposit(receiver.address, depositor.address, token.address, getBigNumber(1000), 0, false, "TEST").should.be.revertedWith("resolver cannot be party");
    await locker.deposit(receiver.address, receiver.address, token.address, getBigNumber(1000), 0, false, "TEST").should.be.revertedWith("resolver cannot be party");
  });

  it("Should forbid BentoBox deposit if resolver is party to locker", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
    
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(depositor).registerResolver(true, 20);
    await locker.connect(receiver).registerResolver(true, 20);
    await locker.depositBento(receiver.address, depositor.address, token.address, getBigNumber(1000), 0, true, "TEST").should.be.revertedWith("resolver cannot be party");
    await locker.depositBento(receiver.address, receiver.address, token.address, getBigNumber(1000), 0, true, "TEST").should.be.revertedWith("resolver cannot be party");
  });

  it("Should forbid release by non-depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
    
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.connect(receiver).release(1).should.be.revertedWith("not depositor");
    await locker.connect(resolver).release(1).should.be.revertedWith("not depositor");
  });

  it("Should forbid release of nonexistent locker", async function () {
    let lexDAO;
    [lexDAO] = await ethers.getSigners();

    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    await locker.release(1).should.be.reverted;
  });

  it("Should forbid repeat release", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.release(1);
    await locker.release(1).should.be.reverted;
  });

  it("Should forbid release of locked locker", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
    
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
    await locker.connect(receiver).lock(1, "TEST");
    await locker.release(1).should.be.revertedWith("locked");
  });

  it("Should allow withdrawal by depositor after termination time", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.withdraw(1);
  });

  it("Should forbid withdrawal by non-depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.connect(receiver).withdraw(1).should.be.revertedWith("not depositor");
  });

  it("Should forbid withdrawal after lock", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
    await locker.withdraw(1).should.be.revertedWith("locked");
  });

  it("Should forbid withdrawal by depositor before termination time", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    // term is set to August 29, 2023 5:30:30 AM GMT-04:00 DST
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 1693301430, false, "TEST");
    await locker.withdraw(1).should.be.revertedWith("not terminated");
  });

  it("Should forbid withdrawal of nonexistent locker", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    // term is set to August 29, 2023 5:30:30 AM GMT-04:00 DST
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.withdraw(2).should.be.reverted;
  });

  it("Should allow lock by depositor", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
  });

  it("Should allow lock by receiver", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.connect(receiver).lock(1, "TEST");
  });

  it("Should forbid lock by non-party", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();
 
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.connect(resolver).lock(1, "TEST").should.be.revertedWith("not party");
  });

  it("Should forbid lock of nonexistent locker", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
    
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(2).should.be.reverted;
    await locker.connect(receiver).lock(2, "TEST").should.be.reverted;
    await locker.connect(resolver).lock(2, "TEST").should.be.reverted;
  });
 
  it("Should allow resolution by resolver over ERC20", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
    
    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount, "TEST");
  });

  it("Should allow resolution by resolver over ETH", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
    
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST", { value: getBigNumber(1000) });
    await locker.lock(1, "TEST");
    
    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount, "TEST");
  });

  it("Should allow resolution by resolver over BentoBox shares", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const bento = await ethers.getContractAt("IBentoBoxMinimal", bentoAddress);
 
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.depositBento(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, true, "TEST");
    await locker.lock(1, "TEST");

    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount, "TEST");
  });

  it("Should allow resolution by resolver over NFT", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();
 
    const NFT = await ethers.getContractFactory("TestERC721");
    const nft = await NFT.deploy("poc", "poc");
    await nft.deployed();
    
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    await nft.approve(locker.address, 1);
   
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, nft.address, 1, 0, true, "TEST");
    await locker.lock(1, "TEST");

    await locker.connect(resolver).resolve(1, 1, 0, "TEST");
  });

  it("Should forbid resolution by non-resolver", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
    
    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(depositor).resolve(1, resolutionAmount, resolutionAmount, "TEST").should.be.revertedWith("not resolver");
    await locker.connect(receiver).resolve(1, resolutionAmount, resolutionAmount, "TEST").should.be.revertedWith("not resolver");
  });

  it("Should forbid resolution of unlocked locker", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    
    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount, "TEST").should.be.revertedWith("not locked");
  });

  it("Should forbid resolution that is not balanced with locked remainder", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();
 
    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
    
    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount + 100, "TEST").should.be.revertedWith("not remainder");
  });
  
  it("Should forbid repeat resolution", async function () {
    let depositor, receiver, resolver, lexDAO;
    [depositor, receiver, resolver, lexDAO] = await ethers.getSigners();
 
    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    token.approve(locker.address, getBigNumber(10000));
    
    await locker.connect(resolver).registerResolver(true, 20);
    await locker.deposit(receiver.address, resolver.address, token.address, getBigNumber(1000), 0, false, "TEST");
    await locker.lock(1, "TEST");
    
    const resolutionAmount = getBigNumber(1000).div(2);

    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount, "TEST");
    await locker.connect(resolver).resolve(1, resolutionAmount, resolutionAmount, "TEST").should.be.reverted;
  });

  it("Should allow LexDAO to store agreements", async function () {
    let lexDAO;
    [lexDAO] = await ethers.getSigners();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    locker.registerAgreement(1, "TEST");
  });

  it("Should forbid non-LexDAO accounts from storing agreements", async function () {
    let lexDAO, nonLexDAO;
    [lexDAO, nonLexDAO] = await ethers.getSigners();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    locker.connect(nonLexDAO).registerAgreement(1, "TEST").should.be.revertedWith("not LexDAO");
  });

  it("Should allow LexDAO to transfer role", async function () {
    let lexDAO, newLexDAO;
    [lexDAO, newLexDAO] = await ethers.getSigners();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    locker.updateLexDAO(newLexDAO.address);
  });

  it("Should forbid non-LexDAO accounts from transferring role", async function () {
    let lexDAO, newLexDAO, nonLexDAO;
    [lexDAO, newLexDAO, nonLexDAO] = await ethers.getSigners();
 
    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    locker.connect(nonLexDAO).updateLexDAO(newLexDAO.address).should.be.revertedWith("not LexDAO");
  });

  it.skip("Should execute ERC20 token permit", async function () {
    let depositor, lexDAO;
    [depositor, lexDAO] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy("poc", "poc");
    await token.deployed();

    const Locker = await ethers.getContractFactory("LexLocker");
    const locker = await Locker.deploy(bentoAddress, lexDAO.address, wethAddress);
    await locker.deployed();

    const nonce = await token.nonces(depositor.address);

    // deadline is set to August 29, 2023 5:30:30 AM GMT-04:00 DST
    const deadline = 1693301430;

    const digest = getApprovalDigest(
        token,
        {
            owner: depositor.address,
            spender: locker.address,
            value: 1,
        },
        nonce,
        deadline,
        locker.provider._network.chainId
    )
    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(carolPrivateKey.replace("0x", ""), "hex"))

    await token.connect(depositor).permit(depositor.address, locker.address, 1, deadline, v, r, s, {
        from: depositor.address,
    })
  })
});
