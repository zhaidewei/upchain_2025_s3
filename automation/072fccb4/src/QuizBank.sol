// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

event Deposit(address indexed user, uint256 amount);

event Withdraw(address indexed user, uint256 amount);

interface AutomationCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract QuizBank is AutomationCompatibleInterface {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public threshold = 0.01 ether;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function send() public {
        payable(owner).transfer(address(this).balance);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = address(this).balance > threshold;
        performData = "";
    }

    function performUpkeep(bytes calldata performData) external {
        send();
    }
}
