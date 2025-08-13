// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SafeMath
 * @dev 提供安全的数学运算，防止溢出和下溢
 */
library SafeMath {
    /**
     * @dev 返回两个数的加法，在溢出时回滚
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev 返回两个数的减法，在下溢时回滚
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev 返回两个数的乘法，在溢出时回滚
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev 返回两个数的除法，在除零时回滚
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev 返回两个数的模运算，在除零时回滚
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
