const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BigBank Smart Contract System", function () {
    let bigBank, admin, deployer, user1, user2, user3, adminOwner;

    beforeEach(async function () {
        // 获取测试账户
        [deployer, user1, user2, user3, adminOwner] = await ethers.getSigners();

        // 部署BigBank合约
        const BigBank = await ethers.getContractFactory("BigBank");
        bigBank = await BigBank.deploy();
        await bigBank.deployed();

        // 部署Admin合约
        const Admin = await ethers.getContractFactory("Admin");
        admin = await Admin.deploy();
        await admin.deployed();
    });

    describe("1. 合约部署", function () {
        it("应该正确设置BigBank的admin", async function () {
            expect(await bigBank.admin()).to.equal(deployer.address);
        });

        it("应该正确设置Admin的owner", async function () {
            expect(await admin.owner()).to.equal(deployer.address);
        });

        it("应该设置正确的最小存款金额", async function () {
            expect(await bigBank.MIN_DEPOSIT()).to.equal(ethers.utils.parseEther("0.001"));
        });

        it("应该初始化为零余额", async function () {
            expect(await bigBank.getContractBalance()).to.equal(0);
            expect(await admin.getBalance()).to.equal(0);
        });
    });

    describe("2. 存款功能", function () {
        it("应该接受大于最小金额的存款", async function () {
            const depositAmount = ethers.utils.parseEther("0.005");
            await expect(bigBank.connect(user1).deposit({ value: depositAmount }))
                .to.not.be.reverted;

            expect(await bigBank.balances(user1.address)).to.equal(depositAmount);
            expect(await bigBank.getContractBalance()).to.equal(depositAmount);
        });

        it("应该拒绝小于最小金额的存款", async function () {
            const smallAmount = ethers.utils.parseEther("0.0005");
            await expect(bigBank.connect(user1).deposit({ value: smallAmount }))
                .to.be.revertedWith("Deposit amount must be at least 0.001 ether");
        });

        it("应该接受正好等于最小金额的存款", async function () {
            const minAmount = ethers.utils.parseEther("0.001");
            await expect(bigBank.connect(user1).deposit({ value: minAmount }))
                .to.not.be.reverted;

            expect(await bigBank.balances(user1.address)).to.equal(minAmount);
        });

        it("应该支持多个用户存款", async function () {
            const amount1 = ethers.utils.parseEther("0.003");
            const amount2 = ethers.utils.parseEther("0.005");
            const amount3 = ethers.utils.parseEther("0.002");

            await bigBank.connect(user1).deposit({ value: amount1 });
            await bigBank.connect(user2).deposit({ value: amount2 });
            await bigBank.connect(user3).deposit({ value: amount3 });

            expect(await bigBank.balances(user1.address)).to.equal(amount1);
            expect(await bigBank.balances(user2.address)).to.equal(amount2);
            expect(await bigBank.balances(user3.address)).to.equal(amount3);
            expect(await bigBank.getDepositorsCount()).to.equal(3);
        });

        it("应该通过receive函数接受直接转账", async function () {
            const amount = ethers.utils.parseEther("0.002");
            await expect(user1.sendTransaction({ to: bigBank.address, value: amount }))
                .to.not.be.reverted;

            expect(await bigBank.balances(user1.address)).to.equal(amount);
        });
    });

    describe("3. 管理员权限转移", function () {
        it("应该允许admin转移权限", async function () {
            await expect(bigBank.transferAdmin(admin.address))
                .to.not.be.reverted;

            expect(await bigBank.admin()).to.equal(admin.address);
        });

        it("应该拒绝非admin转移权限", async function () {
            await expect(bigBank.connect(user1).transferAdmin(admin.address))
                .to.be.revertedWith("Only admin can call this function");
        });

        it("应该拒绝转移给零地址", async function () {
            await expect(bigBank.transferAdmin(ethers.constants.AddressZero))
                .to.be.revertedWith("New admin cannot be zero address");
        });

        it("应该拒绝转移给相同地址", async function () {
            await expect(bigBank.transferAdmin(deployer.address))
                .to.be.revertedWith("New admin cannot be the same as current admin");
        });
    });

    describe("4. 前3名存款用户", function () {
        it("应该正确计算前3名存款用户", async function () {
            // 用户存款
            await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("0.005") });
            await bigBank.connect(user2).deposit({ value: ethers.utils.parseEther("0.003") });
            await bigBank.connect(user3).deposit({ value: ethers.utils.parseEther("0.008") });

            const topDepositors = await bigBank.getTopDepositors();

            // 验证排序 (user3: 0.008, user1: 0.005, user2: 0.003)
            expect(topDepositors[0].depositor).to.equal(user3.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("0.008"));

            expect(topDepositors[1].depositor).to.equal(user1.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("0.005"));

            expect(topDepositors[2].depositor).to.equal(user2.address);
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("0.003"));
        });

        it("应该处理空状态", async function () {
            const topDepositors = await bigBank.getTopDepositors();
            expect(topDepositors[0].depositor).to.equal(ethers.constants.AddressZero);
            expect(topDepositors[0].amount).to.equal(0);
        });
    });

    describe("5. Admin合约功能", function () {
        beforeEach(async function () {
            // 设置：转移BigBank admin权限给Admin合约
            await bigBank.transferAdmin(admin.address);

            // 添加一些存款
            await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("0.005") });
            await bigBank.connect(user2).deposit({ value: ethers.utils.parseEther("0.003") });
        });

        it("应该允许owner从BigBank提取资金", async function () {
            const initialAdminBalance = await admin.getBalance();
            const bankBalance = await bigBank.getContractBalance();

            await expect(admin.adminWithdraw(bigBank.address))
                .to.not.be.reverted;

            expect(await admin.getBalance()).to.equal(initialAdminBalance.add(bankBalance));
            expect(await bigBank.getContractBalance()).to.equal(0);
        });

        it("应该允许部分提取资金", async function () {
            const withdrawAmount = ethers.utils.parseEther("0.002");
            const initialAdminBalance = await admin.getBalance();

            await expect(admin.adminWithdrawPartial(bigBank.address, withdrawAmount))
                .to.not.be.reverted;

            expect(await admin.getBalance()).to.equal(initialAdminBalance.add(withdrawAmount));
            expect(await bigBank.getContractBalance()).to.equal(ethers.utils.parseEther("0.006"));
        });

        it("应该拒绝非owner提取资金", async function () {
            await expect(admin.connect(user1).adminWithdraw(bigBank.address))
                .to.be.revertedWith("Only owner can call this function");
        });

        it("应该拒绝从零地址提取", async function () {
            await expect(admin.adminWithdraw(ethers.constants.AddressZero))
                .to.be.revertedWith("Bank address cannot be zero");
        });

        it("应该拒绝从空余额银行提取", async function () {
            // 先提取所有资金
            await admin.adminWithdraw(bigBank.address);

            // 尝试再次提取
            await expect(admin.adminWithdraw(bigBank.address))
                .to.be.revertedWith("Bank has no funds to withdraw");
        });
    });

    describe("6. 权限转移功能", function () {
        it("应该允许Admin owner转移权限", async function () {
            await expect(admin.transferOwnership(adminOwner.address))
                .to.not.be.reverted;

            expect(await admin.owner()).to.equal(adminOwner.address);
        });

        it("应该拒绝非owner转移权限", async function () {
            await expect(admin.connect(user1).transferOwnership(adminOwner.address))
                .to.be.revertedWith("Only owner can call this function");
        });

        it("应该允许从Admin合约提取资金到owner", async function () {
            // 先向Admin合约转入一些资金
            await bigBank.transferAdmin(admin.address);
            await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("0.005") });
            await admin.adminWithdraw(bigBank.address);

            const ownerBalanceBefore = await deployer.getBalance();
            const adminBalance = await admin.getBalance();

            await expect(admin.withdrawFromAdmin(adminBalance))
                .to.not.be.reverted;

            expect(await admin.getBalance()).to.equal(0);
        });
    });

    describe("7. 完整工作流程", function () {
        it("应该正确执行完整的系统流程", async function () {
            // 1. 部署并设置
            await bigBank.transferAdmin(admin.address);

            // 2. 用户存款
            await bigBank.connect(user1).deposit({ value: ethers.utils.parseEther("0.005") });
            await bigBank.connect(user2).deposit({ value: ethers.utils.parseEther("0.003") });
            await bigBank.connect(user3).deposit({ value: ethers.utils.parseEther("0.008") });

            // 3. 验证状态
            expect(await bigBank.getContractBalance()).to.equal(ethers.utils.parseEther("0.016"));
            expect(await bigBank.getDepositorsCount()).to.equal(3);

            // 4. Admin提取资金
            const adminBalanceBefore = await admin.getBalance();
            await admin.adminWithdraw(bigBank.address);

            expect(await admin.getBalance()).to.equal(
                adminBalanceBefore.add(ethers.utils.parseEther("0.016"))
            );
            expect(await bigBank.getContractBalance()).to.equal(0);

            // 5. 验证前3名排序
            const topDepositors = await bigBank.getTopDepositors();
            expect(topDepositors[0].depositor).to.equal(user3.address);
            expect(topDepositors[1].depositor).to.equal(user1.address);
            expect(topDepositors[2].depositor).to.equal(user2.address);
        });
    });

    describe("8. 错误处理", function () {
        it("应该拒绝零金额存款", async function () {
            await expect(bigBank.connect(user1).deposit({ value: 0 }))
                .to.be.revertedWith("Deposit amount must be greater than 0");
        });

        it("应该拒绝非admin提取", async function () {
            await expect(bigBank.connect(user1).withdraw(ethers.utils.parseEther("0.001")))
                .to.be.revertedWith("Only admin can call this function");
        });

        it("应该拒绝提取超过余额的金额", async function () {
            await expect(bigBank.withdraw(ethers.utils.parseEther("1.0")))
                .to.be.revertedWith("Insufficient contract balance");
        });
    });
});
