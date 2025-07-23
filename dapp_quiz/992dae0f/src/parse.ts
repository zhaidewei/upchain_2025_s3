#!/usr/bin/env ts-node
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

interface CLIArgs {
  genPrivateKey: boolean;
  privateKey: `0x${string}`;
  chain: 'sepolia' | 'anvil' | 'mainnet';
  to: `0x${string}`;
  value: string;
  data: `0x${string}`;
}

export const argv = yargs(hideBin(process.argv))
  .usage('Usage: $0 [options]')
  .option('genPrivateKey', {
    alias: 'g',
    type: 'boolean',
    demandOption: false,
    default: false,
    describe: 'To generate a private key or not',
  })
  .option('privateKey', {
    alias: 'p',
    type: 'string',
    default: '',
    describe: 'The private key to use',
  })
  .option('chain', {
    alias: 'c',
    type: 'string',
    default: 'anvil',
    choices: ['anvil', 'sepolia', 'mainnet'],
    describe: 'The chain to use, choose from anvil, sepolia, mainnet',
  })
  .option('value', {
    alias: 'v',
    type: 'string',
    describe: 'The value to send the transaction to',
  })
  .option('data', {
    alias: 'd',
    type: 'string',
    describe: 'The data to send the transaction to',
  })
  .parseSync();
