const hre = require("hardhat");


async function main() {
  const accounts = await hre.ethers.getSigners();
  //get 10-th account here as example benefactor for contract minting rewards
  console.log(accounts[9].address)
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
