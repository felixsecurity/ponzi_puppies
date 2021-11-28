require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


//"test test test test test test test test test test test junk"

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      //accounts : {
      //  mnemonic: "<redacted>"
      //}
    },
    tmatic: {
      url: "https://rpc-mumbai.maticvigil.com",
      gasPrice: 8000000000,
      accounts: {
        // deployer mnemonic
        mnemonic: "<redacted>"
      }
    },
    polygon: {
      url: "https://polygon-rpc.com",
      gasPrice: 15000000000, //15Gwei
      accounts: {
        // deployer mnemonic
        mnemonic: "<redacted>"
      }
    }
  }
};

