// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// 1. EIP 191 verification
contract VerifySig {
    // message: 'hello world' -> '0x68656c6c6f20776f726c64' ascii-to-hex

    function verify(bytes memory message, bytes memory signature) public pure returns (address) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(message);
        return ECDSA.recover(hash, signature);
    }

}

// 2. EIP 712 verification
contract VerifySigEip712 is EIP712 {

    struct Send {
        address to;
        uint256 value;
    }

    bytes32 public constant SEND_TYPEHASH = keccak256("Send(address to,uint256 value)");

    // 注意：这里的 domain 必须与 signEip712.ts 中完全匹配
    // TypeScript 中使用的是：
    // name: 'EIP712Verifier', version: '1.0.0', chainId: 31337
    // verifyingContract: 会是这个合约部署后的实际地址
    constructor() EIP712("EIP712Verifier", "1.0.0") {}

    function hashSend(Send memory send) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(SEND_TYPEHASH, send.to, send.value))
        );
    }

    function verify(Send memory send, bytes memory signature) public view returns (address) {
        bytes32 digest = hashSend(send);
        return ECDSA.recover(digest, signature);
    }
}
