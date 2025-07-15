pragma solidity ^0.8.0;

/*
Quiz#5
地址类型

定义一个public address类型变量wallet，值设为任意非零地址
补充完整checkBalance函数，返回该地址余额
补充完整sendEth函数，向该地址发送 ETher
*/

contract AddressDataType {
    address public wallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    constructor() {}

    function checkBalance() public view returns (uint256) {
        return wallet.balance;
    }

    function sendEth(uint256 amount) payable public {
        require(amount >= 0, "Amount must be greater than 0");
        (bool success, ) = payable(wallet).call{value: amount}("");
        require(success, "Send ETH failed");
    }
}
