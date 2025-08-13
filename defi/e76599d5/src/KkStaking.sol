// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {KkErc20} from "./KkErc20.sol";

contract KkStaking is Ownable {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // 用户当前质押的ETH数量
        uint256 rewardDebt; // 可以理解为当前用户amount对应的已经分配过的KkToken的数量
        uint256 kKClaimable; // 已经分配给用户的KkToken总量，但是用户还没有提取到自己的erc20 address里的额度。
            //
            // 基本上，在任意时刻，用户应得但尚未分配的KK数量为：
            //
            //   待领取奖励 = (user.amount * accKkPerShare) - user.rewardDebt
            //
            // 每当用户向池子中存入或提取ETH时，会发生以下操作：
            // 1. 更新池子里的accKkPerShare 和lastRewardBlock 到当前进度。
            // 2. 计算用户的未分配奖励，加入到kKClaimable里面。
            // 3. 使用新的amount去overwrite user.amount
            // 4. 用accKkPerShare * amount 去overwrite user.rewardDebt
    }

    // 单池质押合约的池子信息
    uint256 public lastRewardBlock; // 上一次在ERC20里mint出来Kk的区块号
    uint256 public accKkPerShare; // 这个值是最关键的，它的含义是，从pool开始到现在，你质押的每一个ETH，应该获得多少KK

    // 每个区块产生的KK代币数量
    uint256 public kkPerBlock;
    // The KK TOKEN! 这个合约是KK代币合约
    KkErc20 public kk;
    // Info of each user that stakes ETH tokens.
    mapping(address => UserInfo) public userInfo;

    // The block number when KK mining starts.
    uint256 public startBlock;

    // 添加质押的ETH总量，目前可以只看ETH到余额，但是考虑升级性，我们可能要添加余额质押功能，用单一变量跟踪更灵活
    uint256 public totalStaked;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    constructor(
        KkErc20 _kk, // Erc20奖励KK代币合约地址
        uint256 _kkPerBlock, // 每个区块产生的KK代币数量，初始设置
        uint256 _startBlock // KK挖矿开始的区块号，部署时刻到区块号
    ) Ownable(msg.sender) {
        kk = _kk; // 初始化ERC20合约地址
        kkPerBlock = _kkPerBlock;
        startBlock = _startBlock;
        lastRewardBlock = _startBlock; // 初始化最后奖励区块
    }

    function setKkPerBlock(uint256 _kkPerBlock) public onlyOwner {
        require(_kkPerBlock > 0, "kkPerBlock must be greater than 0");
        require(_kkPerBlock != kkPerBlock, "kkPerBlock already set");
        updatePool(); //先结算，再更新，因为结算的假设是从上一次lastRewardBlock到现在，没有会改变区块奖励的事件发生
        kkPerBlock = _kkPerBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        // 这样写如果_to < _from会返回负数（实际上是uint256下的溢出，变成很大的数），
        // 但在正常用法下，_to 应该总是 >= _from。
        // 为了安全起见，可以加个判断，防止返回负数（溢出）。
        if (_to < _from) {
            return 0;
        }
        return _to - _from;
    }
    // 计算用户在指定池子中待领取的KK数量
    // 从上一次奖励发放到目前，用户应该获得的KK数量

    function pendingKk(address _user) public view returns (uint256) {
        // 获取指定用户在指定池子中的质押信息
        UserInfo storage user = userInfo[_user];
        // 使用质押的ETH总量
        uint256 ethSupply = totalStaked;

        // 如果当前区块号大于最后奖励区块且池子有ETH，则需要计算新的奖励
        if (block.number > lastRewardBlock && ethSupply != 0) {
            // 计算从最后奖励区块到当前区块的奖励倍数
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            // 计算该池子在这段时间内应该获得的KK奖励
            // 更新累计每份KK奖励
            // 公式：原有累计值 + (奖励倍数 × 每区块KK数量 × 1e12) ÷ KK总供应量
            uint256 newaccKkPerShare = accKkPerShare + multiplier * kkPerBlock * 1e12 / ethSupply;
            return user.amount * newaccKkPerShare / 1e12 - user.rewardDebt;
        }

        // 计算用户待领取的KK数量
        // 公式：(用户质押数量 × 累计每份奖励) ÷ 1e12 - 用户奖励债务
        return user.amount * accKkPerShare / 1e12 - user.rewardDebt;
    }

    // Update被呼叫，意味着总ETH数量要发生变化了，如果再不结算，新增KK奖励的计算就不能把ethSupply看作是一个常数了。
    // 所以要结算一次，然后做eth变更
    // 结算包括两部分： 1 对外，把奖励Erc0 Token mint出来。2 对内，更新accKkPerShare，更新lastRewardBlock
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 ethSupply = totalStaked; // 使用质押的ETH总量
        if (ethSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 kkReward = multiplier * kkPerBlock;
        kk.mint(address(this), kkReward);
        accKkPerShare = accKkPerShare + kkReward * 1e12 / ethSupply;
        lastRewardBlock = block.number;
    }

    // 质押ETH到KkStaking合约中，获取KK代币
    function stake() external payable {
        require(msg.value > 0, "amount must be greater than 0");
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 pending = pendingKk(msg.sender);
        user.kKClaimable = user.kKClaimable + pending;
        user.amount = msg.value;
        totalStaked = totalStaked + msg.value;
        user.rewardDebt = user.amount * accKkPerShare / 1e12; // accKkPerShare 是放大了1e12倍的
        emit Stake(msg.sender, msg.value);
    }

    // Withdraw ETH from KkStaking.
    function unstake(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "amount must be greater than or equal to user.amount");
        updatePool();
        // 先结算用户应该得到的KK奖励
        uint256 pending = pendingKk(msg.sender);
        user.kKClaimable = user.kKClaimable + pending;
        // 从用户质押的ETH中扣除_amount
        user.amount = user.amount - _amount;
        totalStaked = totalStaked - _amount; // 更新总质押量
        user.rewardDebt = user.amount * accKkPerShare / 1e12; // 更新用户奖励债务
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "ETH transfer failed");
        emit UnStake(msg.sender, _amount);
    }

    // Claim KK rewards，简单起见，直接claim所有奖励
    function claim() external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 pending = pendingKk(msg.sender);
        bool success = kk.transfer(msg.sender, user.kKClaimable + pending);
        require(success, "KK transfer failed");
        user.kKClaimable = 0;
        if (pending > 0) {
            // 说明用户的未获得奖励得到更新，但是user amount没有变化，所以只要更新rewardDebt和claimable即可
            user.rewardDebt = user.amount * accKkPerShare / 1e12;
        }
    }

    // 实现接口要求的函数
    function balanceOf(address account) external view returns (uint256) {
        return userInfo[account].amount;
    }

    function earned(address account) external view returns (uint256) {
        return pendingKk(account);
    }
}
