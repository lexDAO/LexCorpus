require('@nomiclabs/hardhat-waffle');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '^0.8.0',
    settings: {
      optimizer: {
        enabled: true,
        runs: 283
      }
    }
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    }
  }
};
