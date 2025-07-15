pragma solidity ^0.8.0;

/*
Quiz#2
布尔类型

定义一个public bool类型变量isActive，默认值设为true
补充完整switchStatus函数，每次调用时切换isActive状态
*/

contract BooleanDataType {
    bool public isActive = true;

    function switchStatus() public {
        isActive = !isActive;
    }

}
