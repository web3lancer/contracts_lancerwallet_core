const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Wallet", function () {
  it("deploys factory and wallet and executes tx", async function () {
    const [owner1, owner2, recipient] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("WalletFactory");
    const factory = await Factory.deploy();
    await factory.deployed();

    const tx = await factory.createWallet([owner1.address, owner2.address], 2);
    const rc = await tx.wait();
    const ev = rc.events.find(e => e.event === 'WalletCreated');
    const walletAddr = ev.args.wallet;
    const Wallet = await ethers.getContractAt("Wallet", walletAddr);

    // fund wallet
    await owner1.sendTransaction({to: walletAddr, value: ethers.utils.parseEther('1')});

    // prepare execute to send 0.5 ETH to recipient
    const to = recipient.address;
    const value = ethers.utils.parseEther('0.5');
    const data = "0x";
    const nonce = await Wallet.nonce();
    const hash = await Wallet.getTransactionHash(to, value, data, nonce);

    // sign hash
    const sig1 = await owner1.signMessage(ethers.utils.arrayify(hash));
    const sig2 = await owner2.signMessage(ethers.utils.arrayify(hash));

    // execute
    await Wallet.execute(to, value, data, [sig1, sig2]);

    const bal = await ethers.provider.getBalance(walletAddr);
    expect(bal).to.equal(ethers.utils.parseEther('0.5'));
  });
});
