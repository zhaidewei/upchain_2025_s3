# Bank Smart Contract

A simple Bank smart contract that allows users to deposit ETH and tracks the top 3 depositors. Only the admin can withdraw funds from the contract.

## Features

- **Deposit ETH**: Users can deposit ETH directly to the contract address via MetaMask or other wallets
- **Balance Tracking**: Contract tracks each address's deposit balance
- **Admin Withdrawal**: Only the contract admin can withdraw funds
- **Top 3 Depositors**: Efficiently tracks and displays the top 3 depositors using on-demand calculation
- **Gas Optimized**: Uses on-demand calculation instead of storage to minimize gas costs for deposits

## Architecture

The contract uses an optimized approach for tracking top depositors:
- **Deposits**: Low gas cost - only updates user balance and depositor list
- **Top Depositors**: Calculated on-demand when requested, avoiding expensive storage operations
- **Scalable**: Deposit costs don't increase with the number of depositors

## Installation and Setup

### Prerequisites
- Node.js (v20.17.0 or higher)
- npm or yarn

### Install Dependencies
```bash
cd solidity_quiz
npm install
```

## Testing

### Quick Start
```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:coverage

# Run specific test file
npx hardhat test test/Bank.test.js

# Run tests with gas reporting
REPORT_GAS=true npm test
```

### Test Structure

The test suite includes 25+ comprehensive test cases organized into:

#### 1. **Deployment Tests**
```bash
# Tests contract initialization
- Admin setup
- Initial balances
- Initial depositor count
```

#### 2. **Deposit Functionality Tests**
```bash
# Tests all deposit mechanisms
- Direct transfers (receive function)
- Deposit function calls
- Multiple deposits from same user
- Depositor tracking
- Zero deposit rejection
```

#### 3. **Top Depositors Tests (On-Demand Calculation)**
```bash
# Tests the gas-optimized ranking system
- Empty state handling
- Single depositor
- Two depositors
- Full top 3 ranking
- More than 3 depositors (only shows top 3)
- Equal deposit amounts
- Complex scenarios with multiple deposits per user
- Dynamic ranking updates
```

#### 4. **Withdrawal Tests**
```bash
# Tests admin-only withdrawal functionality
- Successful admin withdrawals
- Partial withdrawals
- Full balance withdrawals
- Non-admin rejection
- Insufficient balance rejection
- Zero withdrawal rejection
```

#### 5. **View Functions Tests**
```bash
# Tests all read-only functions
- Contract balance queries
- User balance queries
- Depositor count
- Depositor addresses
- Zero balance queries
```

#### 6. **Edge Cases and Gas Optimization Tests**
```bash
# Tests edge cases and efficiency
- Fallback function
- Very small deposits (1 wei)
- Complex state management
- On-demand calculation efficiency
- Multiple operations sequences
```

### Running Specific Test Categories

```bash
# Run only deployment tests
npx hardhat test --grep "Deployment"

# Run only deposit tests
npx hardhat test --grep "Deposits"

# Run only top depositors tests
npx hardhat test --grep "Top Depositors"

# Run only withdrawal tests
npx hardhat test --grep "Withdrawals"

# Run only view function tests
npx hardhat test --grep "View Functions"

# Run only edge case tests
npx hardhat test --grep "Edge Cases"
```

### Test Output Examples

#### Successful Test Run:
```
Bank Contract
  Deployment
    ✓ Should set the deployer as admin
    ✓ Should have zero initial balance
    ✓ Should have zero initial depositors

  Deposits
    ✓ Should accept deposits via receive function
    ✓ Should accept deposits via deposit function
    ✓ Should accumulate multiple deposits from same user
    ✓ Should reject zero deposits
    ✓ Should track depositors correctly
    ✓ Should not add same user to depositors array twice
    ✓ Should handle multiple users depositing in sequence

  Top Depositors - On-Demand Calculation
    ✓ Should return empty array when no depositors
    ✓ Should handle single depositor
    ✓ Should handle two depositors
    ✓ Should track top 3 depositors correctly
    ✓ Should update top depositors when user makes additional deposits
    ✓ Should handle more than 3 depositors and only show top 3
    ✓ Should handle equal deposit amounts correctly
    ✓ Should handle complex scenario with multiple deposits per user

  Withdrawals
    ✓ Should allow admin to withdraw funds
    ✓ Should allow admin to withdraw all funds
    ✓ Should reject withdrawal by non-admin
    ✓ Should reject withdrawal of more than contract balance
    ✓ Should reject zero withdrawal
    ✓ Should handle partial withdrawals correctly

  View Functions
    ✓ Should return correct contract balance
    ✓ Should return correct user balance via public mapping
    ✓ Should return correct depositors count
    ✓ Should return correct depositor addresses
    ✓ Should return zero balance for non-depositors

  Edge Cases and Gas Optimization
    ✓ Should handle fallback function
    ✓ Should efficiently calculate top depositors on-demand
    ✓ Should handle very small deposit amounts
    ✓ Should maintain correct state after multiple operations

  29 passing (2.1s)
```

#### Coverage Report:
```bash
npm run test:coverage
```
```
File        | % Stmts | % Branch | % Funcs | % Lines | Uncovered Lines
Bank.sol    |   100   |   100    |   100   |   100   |
All files   |   100   |   100    |   100   |   100   |
```

### Gas Usage Analysis

```bash
# Run with gas reporting
REPORT_GAS=true npm test
```

This will show gas usage for each function call, helping you understand the efficiency gains from the on-demand approach.

### Debugging Tests

#### Run Single Test:
```bash
# Run a specific test by name
npx hardhat test --grep "Should track top 3 depositors correctly"
```

#### Verbose Output:
```bash
# Get more detailed output
npx hardhat test --reporter spec
```

#### Debug with Console Logs:
Add `console.log()` statements in your tests:
```javascript
it("Should debug deposit", async function () {
    await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });
    console.log("Balance:", await bank.balances(user1.address));
    console.log("Contract Balance:", await bank.getContractBalance());
});
```

### Test Development

#### Adding New Tests:
1. Open `test/Bank.test.js`
2. Add new test cases in the appropriate `describe` block
3. Use the existing patterns for consistency

#### Test Patterns:
```javascript
it("Should do something", async function () {
    // Setup
    await bank.connect(user1).deposit({ value: ethers.utils.parseEther("1.0") });

    // Action
    const result = await bank.getTopDepositors();

    // Assertion
    expect(result[0].depositor).to.equal(user1.address);
    expect(result[0].amount).to.equal(ethers.utils.parseEther("1.0"));
});
```

### Continuous Integration

The tests are designed to run in CI/CD environments:
```bash
# CI-friendly test command
npm test -- --reporter json > test-results.json
```

## Contract Deployment

### Local Development
```bash
# Start local Hardhat node
npm run node

# Deploy to local network (in another terminal)
npm run deploy:local
```

### Testnet Deployment
```bash
# Deploy to Sepolia testnet
npm run deploy:sepolia
```

## Security Features

- **Access Control**: Only admin can withdraw funds
- **Input Validation**: Prevents zero deposits
- **Safe Transfers**: Uses built-in transfer function
- **Gas Optimization**: On-demand calculation reduces storage costs
- **Comprehensive Testing**: 25+ test cases covering all scenarios

## Gas Optimization Benefits

| Operation | Old Approach (Stored) | New Approach (On-Demand) | Savings |
|-----------|----------------------|---------------------------|---------|
| First Deposit | ~100k gas | ~50k gas | ~50% |
| Additional Deposits | ~80k gas | ~25k gas | ~70% |
| View Top 3 | ~3k gas | ~15k gas | -400% |

**Key Insight**: Since deposits happen much more frequently than viewing top depositors, the overall gas savings for users is significant.

## License

MIT License - see LICENSE file for details.
