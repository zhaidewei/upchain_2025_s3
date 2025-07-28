// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 结论，在sol里不适合做这种歌操作。
contract EventSignature {
    function getEventSignatureHash(string memory eventSignature) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(eventSignature));
    }

    // 0x78d8af3b0529fcbf811085c11d77397246827610c4f2840fcd551f131644bd3a

    /**
     * @dev 获取Transfer事件的哈希值
     */
    function getTransferEventHash() public pure returns (bytes32) {
        return keccak256(abi.encodePacked("Transfer(address indexed, address indexed, uint256)"));
    }

    // /**
    //  * @dev 使用abi.encodeWithSignature计算正规化的事件签名
    //  * 这种方法会自动处理参数的正规化
    //  */
    // function getCanonicalEventSignature(string memory eventName, string memory paramTypes) public pure returns (bytes32) {
    //     string memory fullSignature = string(abi.encodePacked(eventName, "(", paramTypes, ")"));
    //     return keccak256(abi.encodePacked(fullSignature));
    // }

    // /**
    //  * @dev 获取正规化的Transfer事件签名
    //  */
    // function getCanonicalTransferSignature() public pure returns (bytes32) {
    //     return getCanonicalEventSignature("Transfer", "address indexed, address indexed, uint256");
    // }
}
