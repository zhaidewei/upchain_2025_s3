// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ProxyB {
    // uint256 public counter = 0;
    // address public counterA;

    constructor() {
        // counterA = _counterA;
    }

    function incrementViaDelegateCall(address _counterA) public {
        // 这种写法是正确的。delegatecall 会在 ProxyB 的存储上下文中执行 CounterA 的 increment() 逻辑。
        (bool success,) = _counterA.delegatecall(abi.encodeWithSignature("increment()"));
        require(success, "Delegate call failed");
    }
}
