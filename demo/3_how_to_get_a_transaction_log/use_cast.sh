#!/bin/bash
tx="0x59ff0d33333200adc2308ce2a482e0e17ca0d07701f79cf31bcc1804db41daee"
rpc=http://localhost:8545
cast receipt $tx --rpc-url $rpc

cast receipt $tx --rpc-url $rpc --json | jq
