// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CounterA {
    uint256 public counter = 0;

    function increment() public {
        counter = counter + 1;
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}
