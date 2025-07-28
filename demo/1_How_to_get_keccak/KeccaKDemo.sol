// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// run in remix

contract KeccakExample {
    function myKeccak(string memory input) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(input));
        // 0x06b3dfaec148fb1bb2b066f10ec285e7c9bf402ab32aa78a5d38e34566810cd2
    }

    function myKeccak2(string memory input) public pure returns (bytes32) {
        return keccak256(abi.encode(input));
        // 0xcec38027c6953ccda44f5b57cf4fda4925c96672df03eb5b853c4e49d07526fd
        // Note. encode will add type, so it become string input
    }
}
