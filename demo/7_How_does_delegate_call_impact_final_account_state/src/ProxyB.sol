// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ProxyB {
    constructor() {}

    function incrementViaDelegateCall() public {
        // 这种写法是正确的。delegatecall 会在 ProxyB 的存储上下文中执行 CounterA 的 increment() 逻辑。
        (bool success,) =
            address(0x5FbDB2315678afecb367f032d93F642f64180aa3).delegatecall(abi.encodeWithSignature("increment()"));
        require(success, "Delegate call failed");
    }
}
