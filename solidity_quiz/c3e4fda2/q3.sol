// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
Quiz#3
字符串类型

定义一个public string类型变量s1，并赋值为 hello
定义一个public string类型变量s2，并赋值为 world
补充完整combine函数，返回合并s1和s2后的字符串
*/

contract StringDataType {
    string public s1 = "hello";
    string public s2 = "world";
    function combine() public view returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }
}
