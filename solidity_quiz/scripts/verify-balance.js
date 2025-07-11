const { ethers } = require("hardhat");

async function main() {
    console.log("=== 合约余额验证工具 ===");

    // 如果你已经部署了合约，请替换这些地址
    const BIGBANK_ADDRESS = "YOUR_BIGBANK_CONTRACT_ADDRESS"; // 替换为你的BigBank合约地址

    if (BIGBANK_ADDRESS === "YOUR_BIGBANK_CONTRACT_ADDRESS") {
        console.log("❌ 请先在脚本中填入你的BigBank合约地址");
        console.log("💡 你可以通过部署脚本获取合约地址");
        return;
    }

    try {
        // 连接到已部署的合约
        const BigBank = await ethers.getContractFactory("BigBank");
        const bigBank = BigBank.attach(BIGBANK_ADDRESS);

        // 获取合约余额（原始wei值）
        const balanceWei = await bigBank.getContractBalance();

        // 转换为ETH
        const balanceEth = ethers.utils.formatEther(balanceWei);

        console.log("📊 合约余额信息:");
        console.log("├─ 原始值(wei):", balanceWei.toString());
        console.log("├─ 转换值(ETH):", balanceEth);
        console.log("└─ 科学计数法:", balanceWei.toString() === "1000000000000000000" ? "10^18 (1 ETH)" : "其他");

        // 验证是否为1 ETH
        if (balanceWei.toString() === "1000000000000000000") {
            console.log("✅ 确认：合约余额正好是 1 ETH");
        } else if (balanceWei.toString() === "0") {
            console.log("❌ 合约余额为 0");
        } else {
            console.log("ℹ️  合约余额为:", balanceEth, "ETH");
        }

        // 额外信息
        console.log("\n📝 单位换算参考:");
        console.log("├─ 1 ETH = 1,000,000,000,000,000,000 wei");
        console.log("├─ 1 ETH = 10^18 wei");
        console.log("└─ 0.001 ETH = 1,000,000,000,000,000 wei");

    } catch (error) {
        console.error("❌ 错误:", error.message);
        console.log("💡 请确保:");
        console.log("1. 合约地址正确");
        console.log("2. 网络连接正常");
        console.log("3. 合约已正确部署");
    }
}

// 如果需要快速测试，可以部署一个新的合约
async function quickTest() {
    console.log("=== 快速测试模式 ===");

    const [deployer, user1] = await ethers.getSigners();

    // 部署BigBank
    const BigBank = await ethers.getContractFactory("BigBank");
    const bigBank = await BigBank.deploy();
    await bigBank.deployed();

    console.log("📍 BigBank部署地址:", bigBank.address);

    // 用户存款1 ETH
    console.log("\n💰 用户存款1 ETH...");
    await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });

    // 检查余额
    const balanceWei = await bigBank.getContractBalance();
    const balanceEth = ethers.utils.formatEther(balanceWei);

    console.log("📊 存款后余额:");
    console.log("├─ 原始值(wei):", balanceWei.toString());
    console.log("├─ 转换值(ETH):", balanceEth);
    console.log("└─ 是否为1 ETH:", balanceWei.toString() === "1000000000000000000" ? "✅ 是" : "❌ 否");

    // 检查用户余额
    const userBalance = await bigBank.balances(user1.address);
    console.log("\n👤 用户余额:", ethers.utils.formatEther(userBalance), "ETH");
}

// 根据参数决定运行哪个函数
if (process.argv.includes("--quick")) {
    quickTest()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
} else {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = { main, quickTest };
