# Delegate Call Demo

This demo shows how `delegatecall` impacts the final account state.

## Key Concept

`delegatecall` executes the target contract's code in the context of the calling contract. This means:
- The logic runs from the target contract
- The storage changes happen in the calling contract
- The `msg.sender` remains the original caller

## Contracts

1. **CounterA.sol** - A simple counter contract with an `increment()` function
2. **ProxyB.sol** - A proxy contract that uses `delegatecall` to call CounterA's `increment()` function

## How it works

1. Deploy CounterA (target contract)
2. Deploy ProxyB with CounterA's address as the target
3. When ProxyB calls `incrementViaDelegateCall()`:
   - It uses `delegatecall` to execute CounterA's `increment()` logic
   - The increment happens in ProxyB's storage (not CounterA's)
   - CounterA's counter remains unchanged
   - ProxyB's counter gets incremented

## Running the Demo

```bash
# Install dependencies
forge install foundry-rs/forge-std

# Run tests
forge test -vv
```

## Expected Output

The tests will show that:
- Direct calls to CounterA increment CounterA's counter
- Delegate calls through ProxyB increment ProxyB's counter (not CounterA's)
- Both contracts maintain separate counter states

This demonstrates that `delegatecall` changes the storage context but executes the target's logic.
