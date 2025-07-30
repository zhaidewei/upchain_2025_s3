# [quiz](https://decert.me/quests/6a5ce6d6-0502-48be-8fe4-e38a0b35df62)

Quiz#1
先查看先前 NFTMarket 的各函数消耗，测试用例的 gas report 记录到 gas_report_v1.md
尝试优化 NFTMarket 合约，尽可能减少 gas ，测试用例 用例的 gas report 记录到 gas_report_v2.md
提交你的 github 代码库链接

# Knowledge points

# Analysis

## 1. Copy the previous contract here. Add test cases, show gas comsumption of each function

Q: Which command can test and show gas consumption?

```sh
forge test --help
...

 --match-test <REGEX>         Only run test functions matching the specified regex pattern [aliases: --mt]

--gas-report  Print a gas report [env: FORGE_GAS_REPORT=]
--gas-snapshot-check <GAS_SNAPSHOT_CHECK>  Check gas snapshots against previous runs [env: FORGE_SNAPSHOT_CHECK=] [possible values: true, false]

```


## 2. Analysis and improve it

```sh
╭--------------------------------------+-----------------+-------+--------+--------+---------╮
| src/NFTMarket.sol:NFTMarket Contract |                 |       |        |        |         |
+============================================================================================+
| Deployment Cost                      | Deployment Size |       |        |        |         |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| 1929651                              | 11240           |       |        |        |         |
|--------------------------------------+-----------------+-------+--------+--------+---------|
|                                      |                 |       |        |        |         |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| Function Name                        | Min             | Avg   | Median | Max    | # Calls |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| DOMAIN_NAME                          | 3344            | 3344  | 3344   | 3344   | 1       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| DOMAIN_SEPARATOR                     | 6196            | 6196  | 6196   | 6196   | 9       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| DOMAIN_VERSION                       | 3365            | 3365  | 3365   | 3365   | 1       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| NFT_CONTRACT                         | 592             | 592   | 592    | 592    | 1       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| PAYMENT_TOKEN                        | 592             | 592   | 592    | 592    | 1       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| getListing                           | 7478            | 7478  | 7478   | 7478   | 4       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| list                                 | 22283           | 80721 | 101176 | 101176 | 14      |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| owner                                | 2582            | 2582  | 2582   | 2582   | 1       |
|--------------------------------------+-----------------+-------+--------+--------+---------|
| permitBuy                            | 25090           | 58359 | 47968  | 103321 | 8       |
╰--------------------------------------+-----------------+-------+--------+--------+---------╯
```

Now that we see the top 3 gas comsumption functions are:

```
1 change price from uint256 to uint64

It still provides enough capacity of nft prices, `2**64 / 10**18 = 1.8 * 10 ** 12 eth`
But saves many gas.

2. Remove unnecessary DOMAIN_NAME and DOMAIN_VERSION storage
These strings are only used in DOMAIN_SEPARATOR() but we can hardcode them since they're constants.
3. Optimize the Listing struct further
We can pack the struct even more efficiently by using a single uint256 to store multiple values.

4. Remove redundant checks
Same checks to be done only once

5. Optimize event emissions
Remove unnecessary indexed parameters.
```
