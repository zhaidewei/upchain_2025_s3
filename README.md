# upchain_2025_s7

* The repo name contained a typo of s3 which I meant by s7, too late to change, so be it.

* This is a public repo containing my homeworks of the 登链社区 bootcamp of web3 held in 2025 July and August, Zhuhai, China.

* Original homeworks are from [decer.me](https://decert.me/challenge/)

## Structure

1. Repo structure

Each folder covers a topic of learning.

```sh
├── advance_contract
├── automation
├── cache
├── dapp_quiz
├── defi
├── demo # Here I placed many small tests from the course, homeworks are complete project, but I find code snips are useful.
├── foundry_quiz
├── quizs # deprecated, contains first quiz
├── security
└── sol_quiz
```

2. Structure of a quiz

2.1 quiz folder naming
Each quiz folder (named after the first part of a decert me URL)/n
`https://decert.me/challenge/1fa3ecbc-a3cd-43ae-908e-661aac97bdc0` -> `1fa3ecbc`

2.2 `quiz.md` file

This file contains the quiz description, url link, and the solution thought that I came up with

2.3 (usually) a `deploy_and_test.sh` script

This script is a E2E testing script, that starts from an empty Anvil (local chain) environment.

Prepare the environment like contract deployment and user actions.

It represent basically, what should be done in the quiz.

By using such a script, I am using semi automated TDD to speed up the quiz solving speed.

2.4 Srouce files

If the quiz requires to write only code on chain, then I use the root folder as a foundry project.
Otherwise, I separate codes to `on_chain` part and `off_chain` part.
