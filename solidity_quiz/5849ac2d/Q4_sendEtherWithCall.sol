// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*Quiz#4
使用 call 方法来发送 Ether

补充完整 Caller 合约 的 sendEther 方法，用于向指定地址发送 Ether。要求：

使用 call 方法发送 Ether
如果发送失败，抛出“sendEther failed”异常并回滚交易。
如果发送成功，则返回 true
*/

contract Caller {
    function sendEther(address to, uint256 value) public returns (bool) {
        // 使用 call 发送 ether
        (bool success, ) = payable(to).call{value: value}("");

        require(success, "sendEther failed");
        return success;
    }

    receive() external payable {}
}
