// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface for ERC2612 permit functionality
interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract TokenBank {
    // The ERC20 token this bank manages
    IERC20 public immutable token;


    // 记录每个地址的存款金额
    mapping(address user => uint256 balance) public balances;

    // 记录所有存款用户的地址
    address[] public depositors;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PermitDeposit(address indexed user, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
    }

    // 普通存款函数 - 需要预先approve
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");

        // 检查用户是否已经approve足够的额度给TokenBank
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance, please approve first");

        // 如果是新用户，添加到存款者数组
        if (balances[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        // 更新用户余额
        balances[msg.sender] += amount;

        // 转移代币到合约
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "TransferFrom failed");

        emit Deposit(msg.sender, amount);
    }

    // 通过permit签名进行存款 - 无需预先approve
    function permitDeposit(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(owner != address(0), "Owner cannot be zero address");
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        // 使用permit授权代币转移
        // IERC2612 的 permit 如果签名无效或参数不对会 revert（回滚），不需要额外 require 检查
        IERC2612(address(token)).permit(
            owner, // owner is not msg.sender, msg.sender can be anyone.
            address(this), // spender must be the tokenbank address.
            amount,
            deadline,
            v,
            r,
            s);

        // 如果是新用户，添加到存款者数组
        if (balances[owner] == 0) {
            depositors.push(owner);
        }

        // 更新用户余额
        balances[owner] += amount;

        // 转移代币到合约
        bool success = token.transferFrom(owner, address(this), amount);
        require(success, "TransferFrom failed");

        emit PermitDeposit(owner, amount);
    }

    // 用户提取自己的存款
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient user balance");

        // 更新用户余额
        balances[msg.sender] -= amount;

        // 发送代币给用户, transfer 不需要approve，可以直接转
        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    // 查看合约代币余额
    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // 获取存款用户总数
    function getDepositorsCount() external view returns (uint256) {
        return depositors.length;
    }

    // 获取用户存款余额
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
