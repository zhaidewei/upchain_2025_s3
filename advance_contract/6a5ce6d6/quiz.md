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

### Results

```sh
╭--------------------------------------+-----------------+-------+--------+-------+---------╮
| src/NFTMarket.sol:NFTMarket Contract |                 |       |        |       |         |
+===========================================================================================+
| Deployment Cost                      | Deployment Size |       |        |       |         |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| 1481593                              | 7472            |       |        |       |         |
|--------------------------------------+-----------------+-------+--------+-------+---------|
|                                      |                 |       |        |       |         |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| Function Name                        | Min             | Avg   | Median | Max   | # Calls |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| DOMAIN_NAME                          | 740             | 740   | 740    | 740   | 1       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| DOMAIN_SEPARATOR                     | 1336            | 1336  | 1336   | 1336  | 9       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| DOMAIN_VERSION                       | 651             | 651   | 651    | 651   | 1       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| NFT_CONTRACT                         | 592             | 592   | 592    | 592   | 1       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| PAYMENT_TOKEN                        | 570             | 570   | 570    | 570   | 1       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| getListing                           | 3566            | 3566  | 3566   | 3566  | 4       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| list                                 | 22024           | 48867 | 56688  | 56688 | 14      |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| owner                                | 2560            | 2560  | 2560   | 2560  | 1       |
|--------------------------------------+-----------------+-------+--------+-------+---------|
| permitBuy                            | 25060           | 52324 | 39155  | 99354 | 8       |
╰--------------------------------------+-----------------+-------+--------+-------+---------╯
```

```sh
Ran 17 tests for test/NFTMarket.t.sol:NFTMarketTest
[PASS] test_Constructor() (gas: 27948)
[PASS] test_DOMAIN_SEPARATOR() (gas: 10986)
[PASS] test_Events() (gas: 149158)
[PASS] test_GetListing() (gas: 78198)
[PASS] test_GetListingNotListed() (gas: 14129)
[PASS] test_ListNFT() (gas: 78219)
[PASS] test_PermitBuy() (gas: 153199)
[PASS] test_RevertWhen_ListNFTAlreadyListed() (gas: 79437)
[PASS] test_RevertWhen_ListNFTNotApproved() (gas: 22736)
[PASS] test_RevertWhen_ListNFTNotOwner() (gas: 18751)
[PASS] test_RevertWhen_ListNFTZeroPrice() (gas: 45581)
[PASS] test_RevertWhen_PermitBuyExpiredDeadline() (gas: 118327)
[PASS] test_RevertWhen_PermitBuyInsufficientAllowance() (gas: 129747)
[PASS] test_RevertWhen_PermitBuyInsufficientBalance() (gas: 164141)
[PASS] test_RevertWhen_PermitBuyInvalidSignature() (gas: 126459)
[PASS] test_RevertWhen_PermitBuyNFTNotListed() (gas: 63088)
[PASS] test_RevertWhen_PermitBuyPriceMismatch() (gas: 126832)
Suite result: ok. 17 passed; 0 failed; 0 skipped; finished in 25.17ms (82.99ms CPU time)

Ran 1 test suite in 390.99ms (25.17ms CPU time): 17 tests passed, 0 failed, 0 skipped (17 total tests)
test_RevertWhen_ListNFTZeroPrice() (gas: -335 (-0.730%))
test_RevertWhen_ListNFTNotApproved() (gas: -335 (-1.452%))
test_RevertWhen_ListNFTNotOwner() (gas: -335 (-1.755%))
test_RevertWhen_PermitBuyNFTNotListed() (gas: -9968 (-13.644%))
test_Constructor() (gas: -5362 (-16.097%))
test_PermitBuy() (gas: -40098 (-20.744%))
test_Events() (gas: -40462 (-21.338%))
test_GetListingNotListed() (gas: -3900 (-21.632%))
test_RevertWhen_PermitBuyInsufficientBalance() (gas: -50411 (-23.496%))
test_RevertWhen_PermitBuyInsufficientAllowance() (gas: -50285 (-27.931%))
test_RevertWhen_PermitBuyPriceMismatch() (gas: -50693 (-28.555%))
test_RevertWhen_PermitBuyInvalidSignature() (gas: -50585 (-28.572%))
test_RevertWhen_PermitBuyExpiredDeadline() (gas: -49740 (-29.595%))
test_DOMAIN_SEPARATOR() (gas: -4860 (-30.670%))
test_RevertWhen_ListNFTAlreadyListed() (gas: -44856 (-36.089%))
test_ListNFT() (gas: -44382 (-36.200%))
test_GetListing() (gas: -44382 (-36.207%))
Overall gas change: -490989 (-25.870%)
```
