pragma solidity ^0.8.0;

/*
Quiz#6
数组类型

定义一个uint类型动态数组变量numbers
完善addNumber函数，可以往numbers数组添加元素
完善getLength函数，返回numbers数组长度
完善getNumberAt函数，通过下标索引访问numbers数组对应元素值
完善removeNumber函数，从numbers数组末尾删除元素
*/

contract ArrayDataType {
    // numbers;
    uint[] public numbers;

    constructor() {}

    function addNumber(uint x) public {
        numbers.push(x);
    }

    function getLength() public view returns (uint) {
        return numbers.length
    }

    function getNumberAt(uint idx) public view returns (uint) {
        require(idx < numbers.length, "Index out of bounds");
        return numbers[idx];
    }

    function removeNumber() public {
        numbers.pop();
    }
}
