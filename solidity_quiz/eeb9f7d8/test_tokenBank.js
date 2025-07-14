const { ethers } = require("hardhat");

async function testTokenBank() {
    console.log("========================================");
    console.log("TokenBank 智能合约测试");
    console.log("========================================");

    // 获取测试账户
    const [deployer, user1, user2, user3] = await ethers.getSigners();

    console.log("部署者地址:", deployer.address);
    console.log("用户1地址:", user1.address);
    console.log("用户2地址:", user2.address);
    console.log("用户3地址:", user3.address);

    // 1. 部署BaseERC20代币合约
    console.log("\n1. 部署BaseERC20代币合约...");
    const BaseERC20 = await ethers.getContractFactory("BaseERC20");
    const token = await BaseERC20.deploy(
        "BaseERC20",      // name
        "BERC20",         // symbol
        18,               // decimals
        ethers.utils.parseEther("100000000")  // totalSupply: 100,000,000 tokens
    );
    await token.deployed();
    console.log("✅ BaseERC20 部署成功:", token.address);
    console.log("✅ 代币名称:", await token.name());
    console.log("✅ 代币符号:", await token.symbol());
    console.log("✅ 总供应量:", ethers.utils.formatEther(await token.totalSupply()));

    // 2. 部署TokenBank合约
    console.log("\n2. 部署TokenBank合约...");
    const TokenBank = await ethers.getContractFactory("TokenBank");
    const tokenBank = await TokenBank.deploy(token.address);
    await tokenBank.deployed();
    console.log("✅ TokenBank 部署成功:", tokenBank.address);

    // 3. 为用户分发代币
    console.log("\n3. 为用户分发代币...");
    const userAmount = ethers.utils.parseEther("10000"); // 每个用户10,000个代币

    await token.transfer(user1.address, userAmount);
    await token.transfer(user2.address, userAmount);
    await token.transfer(user3.address, userAmount);

    console.log("✅ 用户1代币余额:", ethers.utils.formatEther(await token.balanceOf(user1.address)));
    console.log("✅ 用户2代币余额:", ethers.utils.formatEther(await token.balanceOf(user2.address)));
    console.log("✅ 用户3代币余额:", ethers.utils.formatEther(await token.balanceOf(user3.address)));

    // 4. 测试存款功能
    console.log("\n4. 测试存款功能...");

    // 用户1存款1000个代币
    const depositAmount1 = ethers.utils.parseEther("1000");
    console.log("用户1准备存款:", ethers.utils.formatEther(depositAmount1), "个代币");

    // 首先需要授权
    await token.connect(user1).approve(tokenBank.address, depositAmount1);
    console.log("✅ 用户1已授权TokenBank");

    // 存款
    await tokenBank.connect(user1).deposit(depositAmount1);
    console.log("✅ 用户1存款成功");

    // 检查余额
    const user1Balance = await tokenBank.balanceOf(user1.address);
    console.log("用户1在TokenBank中的余额:", ethers.utils.formatEther(user1Balance));

    // 用户2存款2000个代币
    const depositAmount2 = ethers.utils.parseEther("2000");
    await token.connect(user2).approve(tokenBank.address, depositAmount2);
    await tokenBank.connect(user2).deposit(depositAmount2);
    console.log("✅ 用户2存款", ethers.utils.formatEther(depositAmount2), "个代币");

    // 用户3存款500个代币
    const depositAmount3 = ethers.utils.parseEther("500");
    await token.connect(user3).approve(tokenBank.address, depositAmount3);
    await tokenBank.connect(user3).deposit(depositAmount3);
    console.log("✅ 用户3存款", ethers.utils.formatEther(depositAmount3), "个代币");

    // 5. 检查TokenBank状态
    console.log("\n5. 检查TokenBank状态...");
    console.log("TokenBank总余额:", ethers.utils.formatEther(await tokenBank.totalBalance()));
    console.log("存款用户数量:", await tokenBank.getDepositorsCount());

    // 显示所有存款用户
    const depositorsCount = await tokenBank.getDepositorsCount();
    for (let i = 0; i < depositorsCount; i++) {
        const depositor = await tokenBank.getDepositor(i);
        const balance = await tokenBank.balanceOf(depositor);
        console.log(`存款用户${i + 1}: ${depositor} - 余额: ${ethers.utils.formatEther(balance)}`);
    }

    // 6. 测试提取功能
    console.log("\n6. 测试提取功能...");

    // 用户1提取500个代币
    const withdrawAmount1 = ethers.utils.parseEther("500");
    const user1BeforeWithdraw = await token.balanceOf(user1.address);

    await tokenBank.connect(user1).withdraw(withdrawAmount1);
    console.log("✅ 用户1提取", ethers.utils.formatEther(withdrawAmount1), "个代币");

    const user1AfterWithdraw = await token.balanceOf(user1.address);
    console.log("用户1提取前钱包余额:", ethers.utils.formatEther(user1BeforeWithdraw));
    console.log("用户1提取后钱包余额:", ethers.utils.formatEther(user1AfterWithdraw));
    console.log("用户1在TokenBank中的余额:", ethers.utils.formatEther(await tokenBank.balanceOf(user1.address)));

    // 7. 测试全部提取功能
    console.log("\n7. 测试全部提取功能...");
    const user2BeforeWithdrawAll = await token.balanceOf(user2.address);

    await tokenBank.connect(user2).withdrawAll();
    console.log("✅ 用户2提取全部余额");

    const user2AfterWithdrawAll = await token.balanceOf(user2.address);
    console.log("用户2提取前钱包余额:", ethers.utils.formatEther(user2BeforeWithdrawAll));
    console.log("用户2提取后钱包余额:", ethers.utils.formatEther(user2AfterWithdrawAll));
    console.log("用户2在TokenBank中的余额:", ethers.utils.formatEther(await tokenBank.balanceOf(user2.address)));

    // 8. 测试错误情况
    console.log("\n8. 测试错误情况...");

    // 测试存款0个代币
    try {
        await tokenBank.connect(user1).deposit(0);
        console.log("❌ 错误：应该拒绝存款0个代币");
    } catch (error) {
        console.log("✅ 正确拒绝存款0个代币");
    }

    // 测试提取超过余额
    try {
        await tokenBank.connect(user1).withdraw(ethers.utils.parseEther("10000"));
        console.log("❌ 错误：应该拒绝提取超过余额");
    } catch (error) {
        console.log("✅ 正确拒绝提取超过余额");
    }

    // 测试未授权存款
    try {
        await tokenBank.connect(user1).deposit(ethers.utils.parseEther("1000"));
        console.log("❌ 错误：应该拒绝未授权存款");
    } catch (error) {
        console.log("✅ 正确拒绝未授权存款");
    }

    // 9. 最终状态检查
    console.log("\n9. 最终状态检查...");
    console.log("TokenBank总余额:", ethers.utils.formatEther(await tokenBank.totalBalance()));
    console.log("剩余存款用户数量:", await tokenBank.getDepositorsCount());

    console.log("\n========================================");
    console.log("测试完成！");
    console.log("========================================");
}

// 运行测试
async function main() {
    try {
        await testTokenBank();
    } catch (error) {
        console.error("测试失败:", error);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = { testTokenBank };
