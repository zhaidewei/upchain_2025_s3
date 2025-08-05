## Try to Hack Vault

Read the smart contract `Vault.sol`, try to steal all eth from the vault.

You can write a hacker contract and add some code to pass the `forge test` .

### Tips
you need understand following knowledge points:
1. reentrance
2. ABI encoding
3. delegatecall


### Anvil

```shell
$ anvil
```

### Deploy

```shell
forge script script/Vault.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## test

```
forge test -vvv
```
