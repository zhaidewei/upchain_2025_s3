// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultLogic {
    address public owner;
    bytes32 private password;

    constructor(bytes32 _password) public {
        owner = msg.sender;
        password = _password;
    }

    function changeOwner(bytes32 _password, address newOwner) public {
        if (password == _password) {
            owner = newOwner;
        } else {
            revert("password error");
        }
    }
}

contract Vault {
    address public owner;
    VaultLogic logic;
    mapping(address => uint256) deposites;
    bool public canWithdraw = false;

    constructor(address _logicAddress) public {
        logic = VaultLogic(_logicAddress);
        owner = msg.sender;
    }

    // 本合约不存在的函数，delegate call到logic合约
    fallback() external {
        (bool result,) = address(logic).delegatecall(msg.data);
        if (result) {
            this;
        }
    }

    receive() external payable {}

    // 存款逻辑，向呼叫者转账，然后修改余额为0
    function deposite() public payable {
        deposites[msg.sender] += msg.value;
    }

    // 检查是否解决，如果余额为0，则返回true。貌似没有用
    function isSolve() external view returns (bool) {
        if (address(this).balance == 0) {
            return true;
        }
    }

    function openWithdraw() external {
        // 允许取钱，如果 是owner，那么设置canWithdraw为true，公共开关
        if (owner == msg.sender) {
            canWithdraw = true;
        } else {
            revert("not owner");
        }
    }

    function withdraw() public {
        // 取钱逻辑，如果取钱开关打开，且呼叫者余额大于等于0，向呼叫者转账，然后修改余额为0

        if (canWithdraw && deposites[msg.sender] >= 0) {
            (bool result,) = msg.sender.call{value: deposites[msg.sender]}("");
            if (result) {
                deposites[msg.sender] = 0;
            }
        }
    }
}
