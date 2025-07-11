const { ethers } = require("hardhat");

async function debugDeposit() {
    console.log("=== BigBank 存款调试工具 ===\n");

    const [deployer, user1] = await ethers.getSigners();

    // 1. 部署BigBank合约
    console.log("1. 部署BigBank合约...");
    const BigBank = await ethers.getContractFactory("BigBank");
    const bigBank = await BigBank.deploy();
    await bigBank.deployed();
    console.log("✅ BigBank地址:", bigBank.address);
    console.log("✅ 初始管理员:", await bigBank.admin());

    // 2. 检查初始状态
    console.log("\n2. 检查初始状态...");
    const initialBalance = await bigBank.getContractBalance();
    console.log("📊 初始合约余额:", ethers.utils.formatEther(initialBalance), "ETH");
    console.log("📊 初始合约余额(wei):", initialBalance.toString());

    // 3. 测试小额存款（应该失败）
    console.log("\n3. 测试小额存款 (0.0005 ETH - 应该失败)...");
    try {
        await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("0.0005") });
        console.log("❌ 错误：小额存款应该被拒绝！");
    } catch (error) {
        console.log("✅ 正确：小额存款被拒绝");
        console.log("   错误信息:", error.message.split("'")[1] || error.message);
    }

    // 4. 测试正常存款
    console.log("\n4. 测试正常存款 (1 ETH)...");
    try {
        const depositAmount = ethers.utils.parseEther("1.0");
        const tx = await bigBank.connect(user1).deposit({ value: depositAmount });
        const receipt = await tx.wait();

        console.log("✅ 存款交易成功");
        console.log("   交易哈希:", tx.hash);
        console.log("   Gas使用:", receipt.gasUsed.toString());

        // 检查余额
        const contractBalance = await bigBank.getContractBalance();
        const userBalance = await bigBank.balances(user1.address);

        console.log("📊 存款后状态:");
        console.log("   合约余额(ETH):", ethers.utils.formatEther(contractBalance));
        console.log("   合约余额(wei):", contractBalance.toString());
        console.log("   用户余额(ETH):", ethers.utils.formatEther(userBalance));
        console.log("   用户余额(wei):", userBalance.toString());

        // 验证是否为1 ETH
        if (contractBalance.toString() === "1000000000000000000") {
            console.log("✅ 确认：合约余额正确为 1 ETH");
        } else {
            console.log("❌ 异常：合约余额不是预期的 1 ETH");
        }

    } catch (error) {
        console.log("❌ 存款失败:", error.message);
        return;
    }

    // 5. 检查存款用户数量
    console.log("\n5. 检查存款统计...");
    const depositorsCount = await bigBank.getDepositorsCount();
    console.log("📊 存款用户数量:", depositorsCount.toString());

    // 6. 测试管理员提取
    console.log("\n6. 测试管理员提取...");
    try {
        const contractBalance = await bigBank.getContractBalance();
        const adminBalanceBefore = await deployer.getBalance();

        const tx = await bigBank.withdraw(contractBalance);
        const receipt = await tx.wait();

        const adminBalanceAfter = await deployer.getBalance();
        const newContractBalance = await bigBank.getContractBalance();

        console.log("✅ 管理员提取成功");
        console.log("   提取后合约余额:", ethers.utils.formatEther(newContractBalance), "ETH");
        console.log("   提取后合约余额(wei):", newContractBalance.toString());

        if (newContractBalance.toString() === "0") {
            console.log("✅ 确认：提取后合约余额为 0");
        }

    } catch (error) {
        console.log("❌ 管理员提取失败:", error.message);
    }

    // 7. 总结
    console.log("\n=== 调试总结 ===");
    console.log("如果您看到合约余额为0，可能的原因：");
    console.log("1. 存款交易失败（金额小于0.001 ETH）");
    console.log("2. 管理员已经提取了资金");
    console.log("3. 查看了错误的合约地址");
    console.log("4. 混淆了用户余额和合约余额");
    console.log("\n记住：1000000000000000000 wei = 1 ETH");
}

// 运行调试
debugDeposit()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("调试失败:", error);
        process.exit(1);
    });
