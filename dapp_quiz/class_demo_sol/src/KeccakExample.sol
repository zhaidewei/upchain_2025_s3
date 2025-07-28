// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract KeccakExample {
    function keccak256(string memory input) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(input));
    }
}
