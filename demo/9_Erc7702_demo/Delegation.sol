pragma solidity ^0.8.0;

contract Delegation {
    event Log(string message);

    function initialize() external payable {
        emit Log("Hello World");
    }

    function ping() external {
        emit Log("Pong");
    }
}
