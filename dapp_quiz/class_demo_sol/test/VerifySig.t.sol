// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {VerifySig, VerifySigEip712} from "../src/VerifySig.sol";

contract VerifySigTest is Test {
    VerifySig public verifySig;
    VerifySigEip712 public verifySigEip712;

    function setUp() public {
        verifySig = new VerifySig();
        verifySigEip712 = new VerifySigEip712();
    }

    function test_Verify_without_prefix() public {
        bytes memory message = "Hello World!";
        bytes memory signature = hex"dd407c5cdfa26c1200e805eeed07d9195ce3aacc0d0d3e97e3f542eb474a8a167abf7e0310b5d2e35d2fd39ef59935672fae3d235b6757c5f66396f3df42fee61c";
        address recovered = verifySig.verify(message, signature);
        assertEq(recovered, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function test_Verify_EIP712() public {
        // 1. 设置 chainId 为 31337 (与 signEip712.ts 一致)
        vm.chainId(31337);

        // 2. 设置期望的合约地址 (避免预编译地址，使用普通地址)
        address expectedContractAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

        // 3. 使用 vm.etch 在指定地址部署合约代码
        vm.etch(expectedContractAddress, address(verifySigEip712).code);

        // 4. 创建一个指向该地址的合约实例
        VerifySigEip712 testContract = VerifySigEip712(expectedContractAddress);

        console.log("Using Contract Address:", expectedContractAddress);
        console.log("Using Chain ID:", block.chainid);

        address expectedSigner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // 5. 使用与 signEip712.ts 中相同参数生成的签名
        // 现在这个签名应该是有效的，因为 domain 参数完全匹配了
        bytes memory signature = hex"f46c78c8b2576e06117fa5cbb2ae13fa1c5ff849bef76fa60ebdd92f5643ff113e36970120db648fd8dc28deeffaf2ac84ca4270f5515fc8775152122744fec71b";

        VerifySigEip712.Send memory send = VerifySigEip712.Send({
            to: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            value: 1000000000000000 // 0.001 ETH in wei (parseEther("0.001"))
        });

        address recovered = testContract.verify(send, signature);
        console.log("Expected:", expectedSigner);
        console.log("Recovered:", recovered);

        assertEq(recovered, expectedSigner);
    }
}
