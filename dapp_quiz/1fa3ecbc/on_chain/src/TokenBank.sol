// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

contract TokenBank {
    // The ERC20 token this bank manages
    IERC20 public immutable TOKEN;

    // Permit2 contract address
    address public immutable PERMIT2;

    // 记录每个地址的存款金额
    mapping(address user => uint256 balance) public balances;

    // 记录所有存款用户的地址
    address[] public depositors;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PermitDeposit(address indexed user, uint256 amount);

    constructor(address _token, address _permit2) {
        require(_token != address(0), "Token address cannot be zero");
        require(_permit2 != address(0), "Permit2 address cannot be zero");
        TOKEN = IERC20(_token);
        PERMIT2 = _permit2;
    }

    // Add ERC165 support to prevent execution reverted errors
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        // Return false for ERC20/ERC721 interface IDs to indicate this is not a token contract
        return false;
    }

    // 普通存款函数 - 需要预先approve
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");

        // 检查用户是否已经approve足够的额度给TokenBank
        uint256 allowance = TOKEN.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance, please approve first");

        // 如果是新用户，添加到存款者数组
        if (balances[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        // 更新用户余额
        balances[msg.sender] += amount;

        // 转移代币到合约
        bool success = TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "TransferFrom failed");

        emit Deposit(msg.sender, amount);
    }

    // 通过permit签名进行存款 - 无需预先approve
    function depositWithPermit2(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(owner != address(0), "Owner cannot be zero address");
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        // 创建 PermitTransferFrom 结构体 - 注意：不包含spender字段！
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(TOKEN), amount: amount}),
            nonce: nonce,
            deadline: deadline
        });

        // 创建 SignatureTransferDetails 结构体
        ISignatureTransfer.SignatureTransferDetails memory transferDetails =
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: amount});

        // 使用 Permit2 的 permitTransferFrom 进行签名转移
        // 这个函数会自动将代币从 owner 转移到 address(this)
        // 注意：msg.sender 必须是 EIP712 签名中的 spender
        ISignatureTransfer(PERMIT2).permitTransferFrom(permit, transferDetails, owner, signature);

        // 如果是新用户，添加到存款者数组
        if (balances[owner] == 0) {
            depositors.push(owner);
        }

        // 更新用户余额
        balances[owner] += amount;

        emit PermitDeposit(owner, amount);
    }

    // 用户提取自己的存款
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient user balance");

        // 更新用户余额
        balances[msg.sender] -= amount;

        // 发送代币给用户, transfer 不需要approve，可以直接转
        bool success = TOKEN.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    // 查看合约代币余额
    function getContractBalance() external view returns (uint256) {
        return TOKEN.balanceOf(address(this));
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
