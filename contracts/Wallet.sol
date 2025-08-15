// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Wallet {
    event Execute(address indexed to, uint256 value, bytes data);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public threshold;
    uint256 public nonce;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "Owners required");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");
        for (uint256 i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "Invalid owner");
            require(!isOwner[o], "Owner not unique");
            isOwner[o] = true;
            owners.push(o);
        }
        threshold = _threshold;
    }

    receive() external payable {}

    // Simple execute guarded by signatures: callers must supply concatenated signatures of owners
    function execute(address to, uint256 value, bytes calldata data, bytes[] calldata sigs) external returns (bytes memory) {
        // verify signatures count
        require(sigs.length >= threshold, "Not enough signatures");
        bytes32 txHash = getTransactionHash(to, value, data, nonce);
        nonce++;
        // recover and verify unique owners
        address lastSigner = address(0);
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = recoverSigner(txHash, sigs[i]);
            require(signer > lastSigner, "Signatures not in ascending order or duplicate");
            require(isOwner[signer], "Signer not owner");
            lastSigner = signer;
        }

        (bool success, bytes memory ret) = to.call{value: value}(data);
        require(success, "Call failed");
        emit Execute(to, value, data);
        return ret;
    }

    function addOwner(address owner, bytes[] calldata sigs) external onlyOwner {
        require(owner != address(0), "Invalid owner");
        require(!isOwner[owner], "Already owner");
        // reuse execute flow by requiring threshold signatures over specific data
        bytes memory data = abi.encodeWithSignature("_addOwner(address)", owner);
        _requireValidSignatures(address(this), 0, data, sigs);
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAdded(owner);
    }

    function removeOwner(address owner, bytes[] calldata sigs) external onlyOwner {
        require(isOwner[owner], "Not owner");
        bytes memory data = abi.encodeWithSignature("_removeOwner(address)", owner);
        _requireValidSignatures(address(this), 0, data, sigs);
        isOwner[owner] = false;
        // remove from owners array
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        if (threshold > owners.length) threshold = owners.length;
        emit OwnerRemoved(owner);
    }

    // internal helpers for owner changes
    function _addOwner(address owner) external {
        require(msg.sender == address(this), "Only wallet");
        // actual logic done in addOwner
    }
    function _removeOwner(address owner) external {
        require(msg.sender == address(this), "Only wallet");
        // actual logic done in removeOwner
    }

    function getTransactionHash(address to, uint256 value, bytes calldata data, uint256 _nonce) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), to, value, keccak256(data), _nonce));
    }

    function _requireValidSignatures(address to, uint256 value, bytes memory data, bytes[] calldata sigs) internal view {
        require(sigs.length >= threshold, "Not enough signatures");
        bytes32 txHash = keccak256(abi.encodePacked(address(this), to, value, keccak256(data), nonce));
        address lastSigner = address(0);
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = recoverSigner(txHash, sigs[i]);
            require(signer > lastSigner, "Signatures not in ascending order or duplicate");
            require(isOwner[signer], "Signer not owner");
            lastSigner = signer;
        }
    }

    // EIP-1271: validate signature
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        address signer = recoverSigner(_hash, _signature);
        if (isOwner[signer]) return 0x1626ba7e;
        return 0xffffffff;
    }

    // simple recover supporting r||s||v (65 bytes)
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        if (signature.length != 65) return address(0);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) v += 27;
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }
}
