const hre = require("hardhat");

async function main() {
  const Greetings = await hre.ethers.getContractFactory("Greetings");

  const greetings = await Greetings.deploy(); 

  console.log(`Greetings deployed to: ${await greetings.getAddress()}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
