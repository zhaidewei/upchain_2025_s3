// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Erc20Token.sol";

contract MyTokenTest is Test {
    MyToken token;

    function setUp() public {
        token = new MyToken("MyToken", "MTK");
    }

    function testInitialSupply() public {
        // The deployer should have the initial supply
        assertEq(token.balanceOf(address(this)), 1e10 * 1e18);
        assertEq(token.totalSupply(), 1e10 * 1e18);
    }

    function testTransfer() public {
        address recipient = address(0xBEEF);
        token.transfer(recipient, 1e18);
        assertEq(token.balanceOf(recipient), 1e18);
        assertEq(token.balanceOf(address(this)), (1e10 - 1) * 1e18);
    }
}
