# LancerWallet Smart Contracts

Smart contracts for the LancerWallet multi-chain crypto wallet platform.

## Contracts

### Wallet.sol
A minimal multisig-style smart contract wallet with the following features:
- Multiple owners with configurable threshold signatures
- Execute arbitrary transactions via signature verification
- Add/remove owners through multisig consensus
- Replay protection using nonces
- EIP-1271 signature validation support
- Gas-optimized design

### WalletFactory.sol
Factory contract for deploying Wallet instances:
- Create new wallet contracts with specified owners and threshold
- Emits WalletCreated events for tracking deployments
- Simple deployment pattern for scalability

## Deployment

### Core Testnet2
- **WalletFactory**: `0x1581eAD89db62985c366eb67728C0474b9908A1C`
- **Network**: Core Testnet2 (Chain ID: 1114)
- **RPC**: https://rpc.test2.btcs.network
- **Explorer**: https://scan.test2.btcs.network/

## Usage

### Deploy a New Wallet
```javascript
const factory = await ethers.getContractAt("WalletFactory", "0x1581eAD89db62985c366eb67728C0474b9908A1C");
const tx = await factory.createWallet([owner1, owner2], 2); // 2-of-2 multisig
const receipt = await tx.wait();
const walletAddress = receipt.events.find(e => e.event === "WalletCreated").args.wallet;
```

### Execute Transactions
```javascript
const wallet = await ethers.getContractAt("Wallet", walletAddress);
const txHash = await wallet.getTransactionHash(to, value, data, nonce);
const sig1 = await signer1.signMessage(ethers.utils.arrayify(txHash));
const sig2 = await signer2.signMessage(ethers.utils.arrayify(txHash));
await wallet.execute(to, value, data, [sig1, sig2]);
```

## Development

### Setup
```bash
npm install
cp .env.example .env
# Edit .env with your private key and API keys
```

### Compile
```bash
npx hardhat compile
```

### Test
```bash
npx hardhat test
```

### Deploy
```bash
npx hardhat run --network core_testnet2 scripts/deploy.js
```

## Security Features
- Signature verification in ascending address order prevents duplicates
- Nonce-based replay protection
- Owner uniqueness validation
- Reentrancy-safe execution
- EIP-1271 contract signature standard support

## License
MIT