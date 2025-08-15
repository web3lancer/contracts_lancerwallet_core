// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Wallet.sol";

contract WalletFactory {
    event WalletCreated(address indexed wallet, address[] owners, uint256 threshold);

    function createWallet(address[] memory owners, uint256 threshold) external returns (address) {
        Wallet w = new Wallet(owners, threshold);
        emit WalletCreated(address(w), owners, threshold);
        return address(w);
    }
}
