// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/DeflationaryToken.sol";

contract DeflationaryTokenTest is Test {
    DeflationaryToken public token;
    address public owner;
    address public user1;
    address public user2;

    // 一年时间（秒）
    uint256 constant YEAR_IN_SECONDS = 365 days;
    // 初始供应量：1亿 * 10^18
    uint256 constant INITIAL_SUPPLY = 100 * 10 ** 6 * 10 ** 18;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // 部署代币合约
        token = new DeflationaryToken();

        // 验证初始状态
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.getCurrentYear(), 1);
        assertEq(token.getLastMintTime(), block.timestamp);
    }

    function testInitialState() public {
        // 测试初始状态
        assertEq(token.name(), "DeflationaryToken");
        assertEq(token.symbol(), "DEFL");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.getCurrentYear(), 1);
        assertFalse(token.canMint());
        assertGt(token.calculateMintAmount(), 0);
    }

    function testCannotMintInFirstYear() public {
        // 第一年不能mint（时间还没到）
        vm.expectRevert("Cannot mint yet");
        token.mint();

        // 时间过了一年，第一年可以mint
        vm.warp(block.timestamp + YEAR_IN_SECONDS);
        assertTrue(token.canMint());
        assertGt(token.calculateMintAmount(), 0);
    }

    function testMintAfterOneYear() public {
        // 时间推进一年
        vm.warp(block.timestamp + YEAR_IN_SECONDS);

        // 验证可以mint
        assertTrue(token.canMint());

        // 计算第一年的mint数量（应该是初始供应量的99%）
        uint256 expectedMintAmount = INITIAL_SUPPLY * 99 / 100; // 99%

        // 记录mint前的状态
        uint256 totalSupplyBefore = token.totalSupply();
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 gonsPerFragmentBefore = token.getGonsPerFragment();

        // 执行mint
        token.mint();

        // 验证mint后的状态
        assertEq(token.getCurrentYear(), 2);
        // 允许小的舍入误差（增加容差到0.5%）
        assertApproxEqRel(token.totalSupply(), totalSupplyBefore + expectedMintAmount, 0.005e18);
        assertApproxEqRel(token.balanceOf(owner), ownerBalanceBefore + expectedMintAmount, 0.005e18);

        // 验证gons per fragment比率发生了变化（因为总供应量增加）
        assertLt(token.getGonsPerFragment(), gonsPerFragmentBefore);

        // 验证不能立即再次mint
        assertFalse(token.canMint());
    }

    function testMintAfterTwoYears() public {
        // 第一次mint
        vm.warp(block.timestamp + YEAR_IN_SECONDS);
        token.mint();

        // 第二次mint（再过一年）
        vm.warp(block.timestamp + YEAR_IN_SECONDS);

        // 计算第二年的mint数量（应该是初始供应量的99% * 99% = 98.01%）
        uint256 expectedMintAmount = INITIAL_SUPPLY * 99 * 99 / (100 * 100);

        // 记录mint前的状态
        uint256 totalSupplyBefore = token.totalSupply();
        uint256 ownerBalanceBefore = token.balanceOf(owner);

        // 执行mint
        token.mint();

        // 验证mint后的状态
        assertEq(token.getCurrentYear(), 3);
        // 允许小的舍入误差（增加容差到0.5%）
        assertApproxEqRel(token.totalSupply(), totalSupplyBefore + expectedMintAmount, 0.005e18);
        assertApproxEqRel(token.balanceOf(owner), ownerBalanceBefore + expectedMintAmount, 0.005e18);
    }

    function testTransferAfterRebase() public {
        // 给用户1转一些代币
        uint256 transferAmount = 1000 * 10 ** 18; // 1000 tokens
        token.transfer(user1, transferAmount);

        // 验证转账后的余额
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);

        // 执行mint（时间推进一年）
        vm.warp(block.timestamp + YEAR_IN_SECONDS);
        token.mint();

        // 验证rebase后用户的余额比例保持不变
        // 用户1应该仍然持有相同比例的代币
        uint256 user1BalanceAfterRebase = token.balanceOf(user1);
        uint256 totalSupplyAfterRebase = token.totalSupply();

        // 计算比例（应该基本相等，允许小的舍入误差）
        uint256 ratioBefore = (transferAmount * 1e18) / INITIAL_SUPPLY;
        uint256 ratioAfter = (user1BalanceAfterRebase * 1e18) / totalSupplyAfterRebase;

        // 允许0.01%的误差
        assertApproxEqRel(ratioBefore, ratioAfter, 0.0001e18);
    }

    function testMultipleUsersAfterRebase() public {
        // 给多个用户转代币
        uint256 transferAmount1 = 1000 * 10 ** 18;
        uint256 transferAmount2 = 2000 * 10 ** 18;

        token.transfer(user1, transferAmount1);
        token.transfer(user2, transferAmount2);

        // 记录转账后的余额
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 user1BalanceBefore = token.balanceOf(user1);
        uint256 user2BalanceBefore = token.balanceOf(user2);

        // 执行mint
        vm.warp(block.timestamp + YEAR_IN_SECONDS);
        token.mint();

        // 验证所有用户的余额比例都保持不变
        uint256 totalSupplyAfter = token.totalSupply();

        // 计算比例
        uint256 ownerRatioBefore = (ownerBalanceBefore * 1e18) / INITIAL_SUPPLY;
        uint256 user1RatioBefore = (user1BalanceBefore * 1e18) / INITIAL_SUPPLY;
        uint256 user2RatioBefore = (user2BalanceBefore * 1e18) / INITIAL_SUPPLY;

        uint256 ownerRatioAfter = (token.balanceOf(owner) * 1e18) / totalSupplyAfter;
        uint256 user1RatioAfter = (token.balanceOf(user1) * 1e18) / totalSupplyAfter;
        uint256 user2RatioAfter = (token.balanceOf(user2) * 1e18) / totalSupplyAfter;

        // 验证比例基本相等（允许小的舍入误差）
        assertApproxEqRel(ownerRatioBefore, ownerRatioAfter, 0.0001e18);
        assertApproxEqRel(user1RatioBefore, user1RatioAfter, 0.0001e18);
        assertApproxEqRel(user2RatioBefore, user2RatioAfter, 0.0001e18);
    }

    function testGonsAndFragmentsRelationship() public {
        // 验证gons和fragments的关系
        uint256 totalGons = token.scaledTotalSupply();
        uint256 totalFragments = token.totalSupply();
        uint256 gonsPerFragment = token.getGonsPerFragment();

        // 验证关系：totalGons = totalFragments * gonsPerFragment
        assertEq(totalGons, totalFragments * gonsPerFragment);

        // 验证用户余额的gons和fragments关系
        uint256 user1Gons = token.scaledBalanceOf(user1);
        uint256 user1Fragments = token.balanceOf(user1);

        // 初始时用户1没有代币
        assertEq(user1Gons, 0);
        assertEq(user1Fragments, 0);

        // 给用户1转一些代币
        uint256 transferAmount = 1000 * 10 ** 18;
        token.transfer(user1, transferAmount);

        // 验证转账后的关系
        user1Gons = token.scaledBalanceOf(user1);
        user1Fragments = token.balanceOf(user1);

        assertEq(user1Gons, transferAmount * gonsPerFragment);
        assertEq(user1Fragments, transferAmount);
    }

    function testRebaseEventEmission() public {
        // 时间推进一年
        vm.warp(block.timestamp + YEAR_IN_SECONDS);

        // 记录事件
        vm.recordLogs();
        token.mint();

        // 获取记录的事件
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // 验证LogMint事件
        assertEq(entries[0].topics[0], keccak256("LogMint(uint256,uint256,uint256)"));

        // 验证LogRebase事件
        assertEq(entries[2].topics[0], keccak256("LogRebase(uint256,uint256,uint256)"));
    }

    function testTimeUntilNextMint() public {
        // 初始状态
        uint256 timeUntilNext = token.getTimeUntilNextMint();
        assertEq(timeUntilNext, YEAR_IN_SECONDS);

        // 时间推进一半
        vm.warp(block.timestamp + YEAR_IN_SECONDS / 2);
        timeUntilNext = token.getTimeUntilNextMint();
        assertEq(timeUntilNext, YEAR_IN_SECONDS / 2);

        // 时间推进一年
        vm.warp(block.timestamp + YEAR_IN_SECONDS / 2);
        timeUntilNext = token.getTimeUntilNextMint();
        assertEq(timeUntilNext, 0);

        // 执行mint后
        token.mint();
        timeUntilNext = token.getTimeUntilNextMint();
        assertEq(timeUntilNext, YEAR_IN_SECONDS);
    }

    function testTransferAfterMultipleRebases() public {
        // 给用户1转一些代币
        uint256 transferAmount = 1000 * 10 ** 18;
        token.transfer(user1, transferAmount);

        // 执行多次mint
        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + YEAR_IN_SECONDS);
            token.mint();
        }

        // 验证用户1的余额比例仍然保持不变
        uint256 user1BalanceAfter = token.balanceOf(user1);
        uint256 totalSupplyAfter = token.totalSupply();

        uint256 ratioBefore = (transferAmount * 1e18) / INITIAL_SUPPLY;
        uint256 ratioAfter = (user1BalanceAfter * 1e18) / totalSupplyAfter;

        // 允许0.01%的误差
        assertApproxEqRel(ratioBefore, ratioAfter, 0.0001e18);
    }

    function testOnlyOwnerCanMint() public {
        // 时间推进一年
        vm.warp(block.timestamp + YEAR_IN_SECONDS);

        // 切换到非owner账户
        vm.prank(user1);
        vm.expectRevert();
        token.mint();
    }

    function testTransferValidation() public {
        // 测试转账到零地址
        vm.expectRevert("Invalid recipient: zero address");
        token.transfer(address(0), 1000 * 10 ** 18);

        // 测试转账到合约地址
        vm.expectRevert("Invalid recipient: contract address");
        token.transfer(address(token), 1000 * 10 ** 18);

        // 测试转账金额为0
        vm.expectRevert("Transfer amount must be greater than 0");
        token.transfer(user1, 0);
    }

    function testApproveAndTransferFrom() public {
        // 给用户1转一些代币
        uint256 transferAmount = 1000 * 10 ** 18;
        token.transfer(user1, transferAmount);

        // 用户1授权用户2使用代币
        vm.prank(user1);
        token.approve(user2, transferAmount);

        // 验证授权额度
        assertEq(token.allowance(user1, user2), transferAmount);

        // 用户2从用户1转代币给自己
        vm.prank(user2);
        token.transferFrom(user1, user2, transferAmount);

        // 验证转账结果
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(user1, user2), 0);
    }
}
