const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Bank Contract", function () {
    let bank;
    let admin;
    let user1;
    let user2;
    let user3;
    let user4;
    let user5;

    beforeEach(async function () {
        // Get signers
        [admin, user1, user2, user3, user4, user5] = await ethers.getSigners();

        // Deploy Bank contract
        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy();
        await bank.deployed();
    });

    describe("Deployment", function () {
        it("Should set the deployer as admin", async function () {
            expect(await bank.admin()).to.equal(admin.address);
        });

        it("Should have zero initial balance", async function () {
            expect(await bank.getContractBalance()).to.equal(0);
        });

        it("Should have zero initial depositors", async function () {
            expect(await bank.getDepositorsCount()).to.equal(0);
        });
    });

    describe("Deposits", function () {
                it("Should accept deposits via receive function", async function () {
            const depositAmount = ethers.utils.parseEther("1.0");

            await user1.sendTransaction({
                to: bank.address,
                value: depositAmount
            });

            expect(await bank.balances(user1.address)).to.equal(depositAmount);
            expect(await bank.getContractBalance()).to.equal(depositAmount);
        });

                it("Should accept deposits via deposit function", async function () {
            const depositAmount = ethers.utils.parseEther("2.0");

            await bank.connect(user1).deposit({ value: depositAmount });

            expect(await bank.balances(user1.address)).to.equal(depositAmount);
        });

        it("Should accumulate multiple deposits from same user", async function () {
            const deposit1 = ethers.utils.parseEther("1.0");
            const deposit2 = ethers.utils.parseEther("0.5");

            await bank.connect(user1).deposit({ value: deposit1 });
            await bank.connect(user1).deposit({ value: deposit2 });

            const expectedTotal = deposit1.add(deposit2);
            expect(await bank.balances(user1.address)).to.equal(expectedTotal);
        });

        it("Should reject zero deposits", async function () {
            await expect(
                bank.connect(user1).deposit({ value: 0 })
            ).to.be.revertedWith("Deposit amount must be greater than 0");
        });

        it("Should track depositors correctly", async function () {
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });

            expect(await bank.getDepositorsCount()).to.equal(2);
            expect(await bank.depositors(0)).to.equal(user1.address);
            expect(await bank.depositors(1)).to.equal(user2.address);
        });

        it("Should not add same user to depositors array twice", async function () {
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });

            expect(await bank.getDepositorsCount()).to.equal(1);
            expect(await bank.balances(user1.address)).to.equal(ethers.utils.parseEther("2.0"));
        });

        it("Should handle multiple users depositing in sequence", async function () {
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("3.0") });

            expect(await bank.getDepositorsCount()).to.equal(3);
            expect(await bank.getContractBalance()).to.equal(ethers.utils.parseEther("6.0"));
        });
    });

    describe("Top Depositors - On-Demand Calculation", function () {
        it("Should return empty array when no depositors", async function () {
            const topDepositors = await bank.getTopDepositors();

            expect(topDepositors[0].depositor).to.equal(ethers.constants.AddressZero);
            expect(topDepositors[0].amount).to.equal(0);
            expect(topDepositors[1].depositor).to.equal(ethers.constants.AddressZero);
            expect(topDepositors[1].amount).to.equal(0);
            expect(topDepositors[2].depositor).to.equal(ethers.constants.AddressZero);
            expect(topDepositors[2].amount).to.equal(0);
        });

        it("Should handle single depositor", async function () {
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });

            const topDepositors = await bank.getTopDepositors();

            expect(topDepositors[0].depositor).to.equal(user1.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("1.0"));

            // Other slots should be empty
            expect(topDepositors[1].depositor).to.equal(ethers.constants.AddressZero);
            expect(topDepositors[2].depositor).to.equal(ethers.constants.AddressZero);
        });

        it("Should handle two depositors", async function () {
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("1.0") });

            const topDepositors = await bank.getTopDepositors();

            expect(topDepositors[0].depositor).to.equal(user1.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("2.0"));

            expect(topDepositors[1].depositor).to.equal(user2.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("1.0"));

            // Third slot should be empty
            expect(topDepositors[2].depositor).to.equal(ethers.constants.AddressZero);
            expect(topDepositors[2].amount).to.equal(0);
        });

        it("Should track top 3 depositors correctly", async function () {
            // Make deposits in different amounts
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("3.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("5.0") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user4).deposit({ value: ethers.utils.parseEther("4.0") });

            const topDepositors = await bank.getTopDepositors();

            // Should be ordered: user2 (5.0), user4 (4.0), user1 (3.0)
            expect(topDepositors[0].depositor).to.equal(user2.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("5.0"));

            expect(topDepositors[1].depositor).to.equal(user4.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("4.0"));

            expect(topDepositors[2].depositor).to.equal(user1.address);
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("3.0"));
        });

        it("Should update top depositors when user makes additional deposits", async function () {
            // Initial deposits
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("3.0") });

            // User1 makes a large additional deposit
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("5.0") });

            const topDepositors = await bank.getTopDepositors();

            // User1 should now be first with 6.0 total
            expect(topDepositors[0].depositor).to.equal(user1.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("6.0"));

            expect(topDepositors[1].depositor).to.equal(user3.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("3.0"));

            expect(topDepositors[2].depositor).to.equal(user2.address);
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("2.0"));
        });

        it("Should handle more than 3 depositors and only show top 3", async function () {
            // Make deposits with 5 users
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("3.0") });
            await bank.connect(user4).deposit({ value: ethers.utils.parseEther("4.0") });
            await bank.connect(user5).deposit({ value: ethers.utils.parseEther("5.0") });

            const topDepositors = await bank.getTopDepositors();

            // Should only show top 3: user5 (5.0), user4 (4.0), user3 (3.0)
            expect(topDepositors[0].depositor).to.equal(user5.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("5.0"));

            expect(topDepositors[1].depositor).to.equal(user4.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("4.0"));

            expect(topDepositors[2].depositor).to.equal(user3.address);
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("3.0"));
        });

        it("Should handle equal deposit amounts correctly", async function () {
            // Test with equal amounts
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("2.0") });

            const topDepositors = await bank.getTopDepositors();

            // All should have equal amounts, order depends on insertion order
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("2.0"));
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("2.0"));
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("2.0"));

            // Should contain all three users
            const addresses = [topDepositors[0].depositor, topDepositors[1].depositor, topDepositors[2].depositor];
            expect(addresses).to.include(user1.address);
            expect(addresses).to.include(user2.address);
            expect(addresses).to.include(user3.address);
        });

        it("Should handle complex scenario with multiple deposits per user", async function () {
            // User1: 1.0 + 2.0 = 3.0
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("2.0") });

            // User2: 5.0
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("5.0") });

            // User3: 0.5 + 0.5 + 3.0 = 4.0
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("0.5") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("0.5") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("3.0") });

            // User4: 1.5
            await bank.connect(user4).deposit({ value: ethers.utils.parseEther("1.5") });

            const topDepositors = await bank.getTopDepositors();

            // Should be: user2 (5.0), user3 (4.0), user1 (3.0)
            expect(topDepositors[0].depositor).to.equal(user2.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("5.0"));

            expect(topDepositors[1].depositor).to.equal(user3.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("4.0"));

            expect(topDepositors[2].depositor).to.equal(user1.address);
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("3.0"));
        });
    });

    describe("Withdrawals", function () {
        beforeEach(async function () {
            // Add some funds to the contract
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("5.0") });
        });

                it("Should allow admin to withdraw funds", async function () {
            const withdrawAmount = ethers.utils.parseEther("2.0");
            const initialBalance = await bank.getContractBalance();

            await bank.connect(admin).withdraw(withdrawAmount);

            const finalBalance = await bank.getContractBalance();
            expect(finalBalance).to.equal(initialBalance.sub(withdrawAmount));
        });

                it("Should allow admin to withdraw all funds", async function () {
            const contractBalance = await bank.getContractBalance();

            await bank.connect(admin).withdraw(contractBalance);

            expect(await bank.getContractBalance()).to.equal(0);
        });

        it("Should reject withdrawal by non-admin", async function () {
            await expect(
                bank.connect(user1).withdraw(ethers.utils.parseEther("1.0"))
            ).to.be.revertedWith("Only admin can call this function");
        });

        it("Should reject withdrawal of more than contract balance", async function () {
            const excessiveAmount = ethers.utils.parseEther("10.0");

            await expect(
                bank.connect(admin).withdraw(excessiveAmount)
            ).to.be.revertedWith("Insufficient contract balance");
        });

        it("Should reject zero withdrawal", async function () {
            await expect(
                bank.connect(admin).withdraw(0)
            ).to.be.revertedWith("Withdrawal amount must be greater than 0");
        });

        it("Should handle partial withdrawals correctly", async function () {
            const initialBalance = await bank.getContractBalance();
            const withdrawAmount1 = ethers.utils.parseEther("1.0");
            const withdrawAmount2 = ethers.utils.parseEther("2.0");

            await bank.connect(admin).withdraw(withdrawAmount1);
            await bank.connect(admin).withdraw(withdrawAmount2);

            const finalBalance = await bank.getContractBalance();
            expect(finalBalance).to.equal(initialBalance.sub(withdrawAmount1).sub(withdrawAmount2));
        });
    });

    describe("View Functions", function () {
        beforeEach(async function () {
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("3.0") });
        });

        it("Should return correct contract balance", async function () {
            const expectedBalance = ethers.utils.parseEther("6.0");
            expect(await bank.getContractBalance()).to.equal(expectedBalance);
        });

        it("Should return correct user balance via public mapping", async function () {
            expect(await bank.balances(user1.address)).to.equal(ethers.utils.parseEther("1.0"));
            expect(await bank.balances(user2.address)).to.equal(ethers.utils.parseEther("2.0"));
            expect(await bank.balances(user3.address)).to.equal(ethers.utils.parseEther("3.0"));
        });

        it("Should return correct depositors count", async function () {
            expect(await bank.getDepositorsCount()).to.equal(3);
        });

        it("Should return correct depositor addresses", async function () {
            expect(await bank.depositors(0)).to.equal(user1.address);
            expect(await bank.depositors(1)).to.equal(user2.address);
            expect(await bank.depositors(2)).to.equal(user3.address);
        });

        it("Should return zero balance for non-depositors", async function () {
            expect(await bank.balances(user4.address)).to.equal(0);
            expect(await bank.balances(admin.address)).to.equal(0);
        });
    });

    describe("Edge Cases and Gas Optimization", function () {
                it("Should handle fallback function", async function () {
            const depositAmount = ethers.utils.parseEther("1.0");

            // Call non-existent function to trigger fallback
            await user1.sendTransaction({
                to: bank.address,
                value: depositAmount,
                data: "0x12345678" // Random function selector
            });

            expect(await bank.balances(user1.address)).to.equal(depositAmount);
        });

        it("Should efficiently calculate top depositors on-demand", async function () {
            // Create many depositors to test efficiency
            const users = [user1, user2, user3, user4, user5];
            const amounts = ["1.0", "2.0", "3.0", "4.0", "5.0"];

            for (let i = 0; i < users.length; i++) {
                await bank.connect(users[i]).deposit({
                    value: ethers.utils.parseEther(amounts[i])
                });
            }

            // This should be efficient despite having 5 depositors
            const topDepositors = await bank.getTopDepositors();

            // Verify correct top 3
            expect(topDepositors[0].depositor).to.equal(user5.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("5.0"));

            expect(topDepositors[1].depositor).to.equal(user4.address);
            expect(topDepositors[1].amount).to.equal(ethers.utils.parseEther("4.0"));

            expect(topDepositors[2].depositor).to.equal(user3.address);
            expect(topDepositors[2].amount).to.equal(ethers.utils.parseEther("3.0"));
        });

                it("Should handle very small deposit amounts", async function () {
            const smallAmount = ethers.utils.parseEther("0.000000000000000001"); // 1 wei

            await bank.connect(user1).deposit({ value: smallAmount });

            expect(await bank.balances(user1.address)).to.equal(smallAmount);
        });

        it("Should maintain correct state after multiple operations", async function () {
            // Complex sequence of operations
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
            await bank.connect(user2).deposit({ value: ethers.utils.parseEther("2.0") });
            await bank.connect(admin).withdraw(ethers.utils.parseEther("1.0"));
            await bank.connect(user3).deposit({ value: ethers.utils.parseEther("3.0") });
            await bank.connect(user1).deposit({ value: ethers.utils.parseEther("4.0") });

            // Check final state
            expect(await bank.balances(user1.address)).to.equal(ethers.utils.parseEther("5.0"));
            expect(await bank.balances(user2.address)).to.equal(ethers.utils.parseEther("2.0"));
            expect(await bank.balances(user3.address)).to.equal(ethers.utils.parseEther("3.0"));
            expect(await bank.getDepositorsCount()).to.equal(3);
            expect(await bank.getContractBalance()).to.equal(ethers.utils.parseEther("9.0"));

            const topDepositors = await bank.getTopDepositors();
            expect(topDepositors[0].depositor).to.equal(user1.address);
            expect(topDepositors[0].amount).to.equal(ethers.utils.parseEther("5.0"));
        });
    });
});
