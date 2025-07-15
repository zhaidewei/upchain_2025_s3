pragma solidity ^0.8.0;


/*
Quiz#7
映射(mapping)类型

定义一个public mapping类型变量balances，键类型为address，值类型为uint
补充完整setBalance函数，可以设置某地址的余额
*/

contract MappingDataType {
    // balances
    mapping(address => uint) public balances;

    constructor() {}

    function setBalance(address to, uint amount) public {
        balances[to] = amount;
    }
}
