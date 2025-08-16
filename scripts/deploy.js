const hre = require("hardhat");

async function main() {
  const [deployer, owner1, owner2] = await hre.ethers.getSigners();

  console.log("Deploying contracts with account:", deployer.address);

  // Get factory (ContractFactory)
  const Factory = await hre.ethers.getContractFactory("WalletFactory");

  // Deploy and keep the Contract instance in `factory`
  const factory = await Factory.deploy(); // returns Contract instance
  await factory.waitForDeployment();
  console.log("WalletFactory deployed to:", factory.target);

  // Create a wallet: this returns a TransactionResponse
  const txCreate = await factory.createWallet([deployer.address], 1);
  const rc = await txCreate.wait(); // wait for receipt
  const ev = rc.events && rc.events.find((e) => e.event === "WalletCreated");
  const walletAddress = ev ? ev.args.wallet : null;
  console.log("createWallet tx:", txCreate.hash);
  console.log("Wallet created at:", walletAddress);

  // Optionally fund the wallet with 0.1 ETH from deployer
  if (walletAddress) {
    const fundValue = hre.ethers.utils.parseEther("0.1");
    const fundTx = await deployer.sendTransaction({ to: walletAddress, value: fundValue });
    await fundTx.wait();
    console.log(`Funded wallet ${walletAddress} with 0.1 ETH, tx: ${fundTx.hash}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
