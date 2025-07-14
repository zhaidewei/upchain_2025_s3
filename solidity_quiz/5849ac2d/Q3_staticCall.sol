// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
补充完整 Caller 合约的 callGetData 方法，
使用 staticcall 调用 Callee 合约中 getData 函数，
并返回值。
当调用失败时，抛出“staticcall function failed”异常。
*/

contract Callee {
    function getData() public pure returns (uint256) {
        return 42;
    }
}

contract Caller {
    function callGetData(address callee) public view returns (uint256) {
        // call by staticcall
        bytes4 selector = bytes4(keccak256("getData()"));  // 移除不必要的memory关键字
        (bool success, bytes memory returnData) = callee.staticcall(
            abi.encodeWithSelector(selector)  // getData()不需要参数
        );

        if (!success) {
            revert("staticcall function failed");
        }

        // 解码bytes数据为uint256
        return abi.decode(returnData, (uint256));
    }
}
