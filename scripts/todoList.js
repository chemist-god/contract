const hre = require("hardhat");

async function main() {
  // Get the contract factory for the TodoList contract
  const TodoList = await hre.ethers.getContractFactory("TodoList");

  // Deploy the contract
  const todoList = await TodoList.deploy();

  // Wait for the deployment to be completed
  await todoList.deployed();

  // Log the address of the deployed contract
  console.log("TodoList contract deployed to:", todoList.address);
}

// Execute the main function and handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error deploying contract:", error);
    process.exit(1);
  });