pragma solidity ^0.8.12;

/*
Quiz#4
字节数组

定义一个public bytes变量b1，赋值为hello
定义一个public bytes变量b2，赋值为world
补充完整combine函数，返回合并b1和b2后的字节数组
*/
contract BytesDataType {
    bytes public b1 = "hello";
    bytes public b2 = "world";
    // b2

    function combine() public view returns (bytes memory) {
        return abi.encodePacked(b1, b2);
    }
}
