const { ethers } = require("hardhat");

async function main() {
    const [deployer, user1, user2, user3, adminOwner] = await ethers.getSigners();

    console.log("========================================");
    console.log("BigBank Smart Contract System Deployment");
    console.log("========================================");
    console.log("Deployer address:", deployer.address);
    console.log("Deployer balance:", ethers.utils.formatEther(await deployer.getBalance()));

    // 1. 部署BigBank合约
    console.log("\n1. Deploying BigBank contract...");
    const BigBank = await ethers.getContractFactory("BigBank");
    const bigBank = await BigBank.deploy();
    await bigBank.deployed();
    console.log("BigBank deployed to:", bigBank.address);
    console.log("BigBank admin:", await bigBank.admin());

    // 2. 部署Admin合约
    console.log("\n2. Deploying Admin contract...");
    const Admin = await ethers.getContractFactory("Admin");
    const admin = await Admin.deploy();
    await admin.deployed();
    console.log("Admin deployed to:", admin.address);
    console.log("Admin owner:", await admin.owner());

    // 3. 将BigBank的管理员权限转移给Admin合约
    console.log("\n3. Transferring BigBank admin rights to Admin contract...");
    await bigBank.transferAdmin(admin.address);
    console.log("BigBank new admin:", await bigBank.admin());

    // 4. 模拟用户存款
    console.log("\n4. Simulating user deposits...");
    const depositAmount1 = ethers.utils.parseEther("0.005");
    const depositAmount2 = ethers.utils.parseEther("0.003");
    const depositAmount3 = ethers.utils.parseEther("0.008");

    await bigBank.connect(user1).deposit({ value: depositAmount1 });
    console.log(`User1 deposited ${ethers.utils.formatEther(depositAmount1)} ETH`);

    await bigBank.connect(user2).deposit({ value: depositAmount2 });
    console.log(`User2 deposited ${ethers.utils.formatEther(depositAmount2)} ETH`);

    await bigBank.connect(user3).deposit({ value: depositAmount3 });
    console.log(`User3 deposited ${ethers.utils.formatEther(depositAmount3)} ETH`);

    // 5. 查看合约状态
    console.log("\n5. Checking contract state...");
    console.log("BigBank contract balance:", ethers.utils.formatEther(await bigBank.getContractBalance()));
    console.log("Number of depositors:", await bigBank.getDepositorsCount());

    // 获取前3名存款用户
    const topDepositors = await bigBank.getTopDepositors();
    console.log("Top 3 depositors:");
    for (let i = 0; i < topDepositors.length; i++) {
        if (topDepositors[i].depositor !== ethers.constants.AddressZero) {
            console.log(`  ${i + 1}. ${topDepositors[i].depositor}: ${ethers.utils.formatEther(topDepositors[i].amount)} ETH`);
        }
    }

    // 6. Admin提取资金
    console.log("\n6. Admin withdrawing funds...");
    console.log("Admin balance before:", ethers.utils.formatEther(await admin.getBalance()));

    await admin.adminWithdraw(bigBank.address);

    console.log("Admin balance after:", ethers.utils.formatEther(await admin.getBalance()));
    console.log("BigBank balance after withdrawal:", ethers.utils.formatEther(await bigBank.getContractBalance()));

    // 7. 验证最小存款限制
    console.log("\n7. Testing minimum deposit requirement...");
    try {
        await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("0.0005") });
        console.log("ERROR: Should have rejected small deposit!");
    } catch (error) {
        console.log("✓ Correctly rejected deposit below minimum (0.0005 ETH)");
    }

    // 8. 测试正确的最小存款
    console.log("\n8. Testing valid minimum deposit...");
    const minDeposit = ethers.utils.parseEther("0.001");
    await bigBank.connect(user1).deposit({ value: minDeposit });
    console.log(`✓ Successfully accepted minimum deposit of ${ethers.utils.formatEther(minDeposit)} ETH`);

    console.log("\n========================================");
    console.log("BigBank System Deployment Complete!");
    console.log("========================================");

    // 返回部署的合约地址
    return {
        bigBank: bigBank.address,
        admin: admin.address,
        deployer: deployer.address
    };
}

// 如果直接运行此脚本，执行main函数
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = { main };
