const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Get account balance
  const balance = await deployer.getBalance();
  console.log("Account balance:", ethers.utils.formatEther(balance), "ETH");

  // Deploy the Bank contract
  console.log("\nDeploying Bank contract...");
  const Bank = await ethers.getContractFactory("Bank");
  const bank = await Bank.deploy();

  await bank.deployed();

  console.log("✅ Bank contract deployed successfully!");
  console.log("📍 Contract address:", bank.address);
  console.log("👤 Admin address:", deployer.address);

  // Verify deployment
  console.log("\nVerifying deployment...");
  const admin = await bank.admin();
  const contractBalance = await bank.getContractBalance();

  console.log("Contract admin:", admin);
  console.log("Contract balance:", ethers.utils.formatEther(contractBalance), "ETH");

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: bank.address,
    adminAddress: deployer.address,
    deploymentTime: new Date().toISOString(),
    blockNumber: await ethers.provider.getBlockNumber()
  };

  console.log("\n📋 Deployment Summary:");
  console.log("Network:", deploymentInfo.network);
  console.log("Contract Address:", deploymentInfo.contractAddress);
  console.log("Admin Address:", deploymentInfo.adminAddress);
  console.log("Block Number:", deploymentInfo.blockNumber);
  console.log("Deployment Time:", deploymentInfo.deploymentTime);

  // Instructions for interaction
  console.log("\n🚀 Next Steps:");
  console.log("1. Users can deposit ETH by sending transactions to:", bank.address);
  console.log("2. Admin can withdraw funds using the withdraw() function");
  console.log("3. Check top depositors using getTopDepositors()");
  console.log("4. View contract balance using getContractBalance()");

  return bank;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
