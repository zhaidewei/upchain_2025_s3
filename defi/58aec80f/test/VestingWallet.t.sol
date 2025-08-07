// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Erc20.sol";
import "../src/VestingWallet.sol";

contract VestingWalletTest is Test {
    MyToken public token;
    CustomVestingWallet public vestingWallet;

    address public admin = address(this);
    address public beneficiary = address(0x1); // anvil user 1
    uint256 public constant TOTAL_AMOUNT = 1_000_000 * 10 ** 18; // 1 million tokens
    uint256 public constant CLIFF_MONTHS = 12;
    uint256 public constant VESTING_MONTHS = 24;

    uint256 public startTime;
    uint256 public cliffEndTime;
    uint256 public vestingEndTime;

    function setUp() public {
        // Deploy token
        token = new MyToken();

        // Set start time to current block timestamp
        startTime = block.timestamp;
        cliffEndTime = startTime + (CLIFF_MONTHS * 30 days);
        vestingEndTime = cliffEndTime + (VESTING_MONTHS * 30 days);

        // Deploy vesting wallet
        vestingWallet = new CustomVestingWallet(beneficiary, startTime, CLIFF_MONTHS, VESTING_MONTHS, TOTAL_AMOUNT);

        // Mint tokens to vesting wallet
        token.mint(address(vestingWallet), TOTAL_AMOUNT);

        // Verify initial state
        assertEq(token.balanceOf(address(vestingWallet)), TOTAL_AMOUNT);
        assertEq(vestingWallet.beneficiary(), beneficiary);
        assertEq(vestingWallet.startTime(), startTime);
        assertEq(vestingWallet.totalAmount(), TOTAL_AMOUNT);
        assertEq(vestingWallet.released(), 0);
    }

    function test_InitialState() public {
        // Check that no tokens are vested at start
        assertEq(vestingWallet.vestedAmount(address(token), startTime), 0);
        assertEq(vestingWallet.releasable(address(token)), 0);
        assertEq(token.balanceOf(beneficiary), 0);
    }

    function test_CliffPeriod_NoTokensVested() public {
        // Fast forward to middle of cliff period
        uint256 cliffMiddle = startTime + (CLIFF_MONTHS * 30 days) / 2;
        vm.warp(cliffMiddle);

        assertEq(vestingWallet.vestedAmount(address(token), cliffMiddle), 0);
        assertEq(vestingWallet.releasable(address(token)), 0);

        // Try to release - should revert
        vm.expectRevert("VestingWallet: no tokens to release");
        vestingWallet.release(address(token));
    }

    function test_CliffEnd_NoTokensVested() public {
        // Fast forward to cliff end
        vm.warp(cliffEndTime);

        assertEq(vestingWallet.vestedAmount(address(token), cliffEndTime), 0);
        assertEq(vestingWallet.releasable(address(token)), 0);

        // Try to release - should revert
        vm.expectRevert("VestingWallet: no tokens to release");
        vestingWallet.release(address(token));
    }

    function test_FirstMonthAfterCliff() public {
        // Fast forward to 1 month after cliff
        uint256 oneMonthAfterCliff = cliffEndTime + 30 days;
        vm.warp(oneMonthAfterCliff);

        uint256 expectedVested = TOTAL_AMOUNT / VESTING_MONTHS; // 1/24 of total
        assertEq(vestingWallet.vestedAmount(address(token), oneMonthAfterCliff), expectedVested);
        assertEq(vestingWallet.releasable(address(token)), expectedVested);

        // Release tokens
        uint256 beneficiaryBalanceBefore = token.balanceOf(beneficiary);
        vestingWallet.release(address(token));
        uint256 beneficiaryBalanceAfter = token.balanceOf(beneficiary);

        assertEq(beneficiaryBalanceAfter - beneficiaryBalanceBefore, expectedVested);
        assertEq(vestingWallet.released(), expectedVested);
        assertEq(vestingWallet.releasable(address(token)), 0);
    }

    function test_SixMonthsAfterCliff() public {
        // Fast forward to 6 months after cliff
        uint256 sixMonthsAfterCliff = cliffEndTime + (6 * 30 days);
        vm.warp(sixMonthsAfterCliff);

        uint256 expectedVested = (TOTAL_AMOUNT * 6) / VESTING_MONTHS; // 6/24 of total
        assertEq(vestingWallet.vestedAmount(address(token), sixMonthsAfterCliff), expectedVested);
        assertEq(vestingWallet.releasable(address(token)), expectedVested);

        // Release tokens
        vestingWallet.release(address(token));

        assertEq(vestingWallet.released(), expectedVested);
        assertEq(token.balanceOf(beneficiary), expectedVested);
    }

    function test_TwelveMonthsAfterCliff() public {
        // Fast forward to 12 months after cliff
        uint256 twelveMonthsAfterCliff = cliffEndTime + (12 * 30 days);
        vm.warp(twelveMonthsAfterCliff);

        uint256 expectedVested = (TOTAL_AMOUNT * 12) / VESTING_MONTHS; // 12/24 of total
        assertEq(vestingWallet.vestedAmount(address(token), twelveMonthsAfterCliff), expectedVested);
        assertEq(vestingWallet.releasable(address(token)), expectedVested);

        // Release tokens
        vestingWallet.release(address(token));

        assertEq(vestingWallet.released(), expectedVested);
        assertEq(token.balanceOf(beneficiary), expectedVested);
    }

    function test_VestingComplete() public {
        // Fast forward to vesting end
        vm.warp(vestingEndTime);

        assertEq(vestingWallet.vestedAmount(address(token), vestingEndTime), TOTAL_AMOUNT);
        assertEq(vestingWallet.releasable(address(token)), TOTAL_AMOUNT);

        // Release all tokens
        vestingWallet.release(address(token));

        assertEq(vestingWallet.released(), TOTAL_AMOUNT);
        assertEq(token.balanceOf(beneficiary), TOTAL_AMOUNT);
        assertEq(token.balanceOf(address(vestingWallet)), 0);
    }

    function test_PartialReleases() public {
        // Fast forward to 3 months after cliff
        uint256 threeMonthsAfterCliff = cliffEndTime + (3 * 30 days);
        vm.warp(threeMonthsAfterCliff);

        uint256 expectedVested = (TOTAL_AMOUNT * 3) / VESTING_MONTHS; // 3/24 of total
        assertEq(vestingWallet.releasable(address(token)), expectedVested);

        // Release first batch
        vestingWallet.release(address(token));
        assertEq(vestingWallet.released(), expectedVested);
        assertEq(token.balanceOf(beneficiary), expectedVested);

        // Fast forward another 3 months
        vm.warp(threeMonthsAfterCliff + (3 * 30 days));

        uint256 newExpectedVested = (TOTAL_AMOUNT * 6) / VESTING_MONTHS; // 6/24 of total
        uint256 additionalReleasable = newExpectedVested - expectedVested;

        assertEq(vestingWallet.releasable(address(token)), additionalReleasable);

        // Release second batch
        vestingWallet.release(address(token));
        assertEq(vestingWallet.released(), newExpectedVested);
        assertEq(token.balanceOf(beneficiary), newExpectedVested);
    }

    function test_ReleaseAfterVestingComplete() public {
        // Fast forward past vesting end
        vm.warp(vestingEndTime + 30 days);

        assertEq(vestingWallet.vestedAmount(address(token), block.timestamp), TOTAL_AMOUNT);
        assertEq(vestingWallet.releasable(address(token)), TOTAL_AMOUNT);

        // Release all tokens
        vestingWallet.release(address(token));

        assertEq(vestingWallet.released(), TOTAL_AMOUNT);
        assertEq(token.balanceOf(beneficiary), TOTAL_AMOUNT);

        // Try to release again - should revert
        vm.expectRevert("VestingWallet: no tokens to release");
        vestingWallet.release(address(token));
    }

    function test_AnyoneCanCallRelease() public {
        // Fast forward to 1 month after cliff
        uint256 oneMonthAfterCliff = cliffEndTime + 30 days;
        vm.warp(oneMonthAfterCliff);

        // Call release from a non-beneficiary account
        vm.prank(address(0x999));
        vestingWallet.release(address(token));

        // Tokens should go to beneficiary
        assertEq(token.balanceOf(beneficiary), TOTAL_AMOUNT / VESTING_MONTHS);
    }
}
