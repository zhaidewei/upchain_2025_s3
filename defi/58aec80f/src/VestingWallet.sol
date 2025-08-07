// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CustomVestingWallet {
    using SafeERC20 for IERC20;

    address public immutable beneficiary;
    uint256 public immutable startTime;
    uint256 public immutable cliffDuration; // 12 months in seconds
    uint256 public immutable vestingDuration; // 24 months in seconds
    uint256 public immutable totalAmount;

    uint256 public released;

    event ERC20Released(address indexed token, uint256 amount);

    constructor(
        address beneficiaryAddress,
        uint256 startTimestamp,
        uint256 cliffDurationInMonths,
        uint256 vestingDurationInMonths,
        uint256 totalVestingAmount
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        require(startTimestamp > 0, "VestingWallet: start time is zero");
        require(cliffDurationInMonths > 0, "VestingWallet: cliff duration is zero");
        require(vestingDurationInMonths > 0, "VestingWallet: vesting duration is zero");
        require(totalVestingAmount > 0, "VestingWallet: total amount is zero");

        beneficiary = beneficiaryAddress;
        startTime = startTimestamp;
        cliffDuration = cliffDurationInMonths * 30 days; // Approximate month
        vestingDuration = vestingDurationInMonths * 30 days; // Approximate month
        totalAmount = totalVestingAmount;
    }

    function release(address token) public {
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - released;
        require(releasable > 0, "VestingWallet: no tokens to release");

        released += releasable;
        IERC20(token).safeTransfer(beneficiary, releasable);

        emit ERC20Released(token, releasable);
    }

    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        if (timestamp < startTime) {
            return 0;
        }

        // If we're still in cliff period, no tokens are vested
        if (timestamp < startTime + cliffDuration) {
            return 0;
        }

        // If we're past the cliff + vesting period, all tokens are vested
        if (timestamp >= startTime + cliffDuration + vestingDuration) {
            return totalAmount;
        }

        // Calculate linear vesting from cliff end
        uint256 timeSinceCliffEnd = timestamp - (startTime + cliffDuration);
        uint256 vested = (timeSinceCliffEnd * totalAmount) / vestingDuration;

        return vested;
    }

    function releasable(address token) public view returns (uint256) {
        return vestedAmount(token, uint256(block.timestamp)) - released;
    }
}
