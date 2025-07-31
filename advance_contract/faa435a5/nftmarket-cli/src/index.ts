#!/usr/bin/env node

import { Command } from 'commander';
import { NFTMarketSigner } from './signer.js';
import { PermitBuyData } from './types.js';
import dotenv from 'dotenv';

dotenv.config();

const program = new Command();

program
  .name('nftmarket-cli')
  .description('CLI tool for NFTMarket permitBuy signatures')
  .version('1.0.0');

program
  .command('sign')
  .description('Sign a permitBuy message')
  .requiredOption('-k, --private-key <key>', 'Private key of the admin')
  .requiredOption('-t, --token-id <id>', 'NFT token ID')
  .requiredOption('-b, --buyer <address>', 'Buyer address')
  .requiredOption('-p, --price <amount>', 'Price in wei')
  .requiredOption('-d, --deadline <timestamp>', 'Deadline timestamp')
  .requiredOption('-c, --chain-id <id>', 'Chain ID')
  .requiredOption('-a, --contract-address <address>', 'NFTMarket contract address')
  .option('--domain-name <name>', 'Domain name (default: DeweiERC2612)')
  .option('--domain-version <version>', 'Domain version (default: 1.0)')
  .action(async (options) => {
    try {
      const signer = new NFTMarketSigner(
        options.privateKey,
        BigInt(options.chainId),
        options.contractAddress,
        options.domainName,
        options.domainVersion
      );

      const data: PermitBuyData = {
        tokenId: BigInt(options.tokenId),
        buyer: options.buyer,
        price: BigInt(options.price),
        deadline: BigInt(options.deadline)
      };

      console.log('Signing permitBuy message...');
      console.log('Data:', {
        tokenId: data.tokenId.toString(),
        buyer: data.buyer,
        price: data.price.toString(),
        deadline: data.deadline.toString()
      });

      const signature = await signer.signPermitBuy(data);

      console.log('\nSignature generated:');
      console.log('v:', signature.v);
      console.log('r:', signature.r);
      console.log('s:', signature.s);
      console.log('Full signature:', signature.signature);

      // 验证签名
      const recoveredAddress = signer.verifySignature(data, signature);
      console.log('\nRecovered signer address:', recoveredAddress);
      console.log('Expected signer address:', signer.getSignerAddress());

      if (recoveredAddress.toLowerCase() === signer.getSignerAddress().toLowerCase()) {
        console.log('✅ Signature verification successful!');
      } else {
        console.log('❌ Signature verification failed!');
      }

      // 生成 cast 命令
      console.log('\nCast command for permitBuy:');
      console.log(`cast send ${options.contractAddress} "permitBuy(uint256,uint256,uint256,uint8,bytes32,bytes32)" ${options.tokenId} ${options.price} ${options.deadline} ${signature.v} ${signature.r} ${signature.s} --private-key <BUYER_PRIVATE_KEY>`);

    } catch (error) {
      console.error('Error:', error);
      process.exit(1);
    }
  });

program
  .command('sign-permit')
  .description('Sign an ERC20 permit message')
  .requiredOption('-k, --private-key <key>', 'Private key of the owner')
  .requiredOption('-o, --owner <address>', 'Owner address')
  .requiredOption('-s, --spender <address>', 'Spender address')
  .requiredOption('-v, --value <amount>', 'Value to approve')
  .requiredOption('-d, --deadline <timestamp>', 'Deadline timestamp')
  .requiredOption('-c, --chain-id <id>', 'Chain ID')
  .requiredOption('-a, --contract-address <address>', 'ERC20 contract address')
  .action(async (options) => {
    try {
      const signer = new NFTMarketSigner(
        options.privateKey,
        BigInt(options.chainId),
        options.contractAddress,
        'DeweiERC2612', // ERC20 domain name
        '1.0' // ERC20 domain version
      );

      // 获取当前 nonce
      const nonce = BigInt(1); // 合约期望使用 current nonce + 1，第一次调用时应该是 1

      const data = {
        owner: options.owner,
        spender: options.spender,
        value: BigInt(options.value),
        nonce: nonce,
        deadline: BigInt(options.deadline)
      };

      console.log('Signing ERC20 permit message...');
      console.log('Data:', {
        owner: data.owner,
        spender: data.spender,
        value: data.value.toString(),
        nonce: data.nonce.toString(),
        deadline: data.deadline.toString()
      });

      const signature = await signer.signERC20Permit(data);

      console.log('\nSignature generated:');
      console.log('v:', signature.v);
      console.log('r:', signature.r);
      console.log('s:', signature.s);
      console.log('Full signature:', signature.signature);

      // 验证签名
      const recoveredAddress = signer.verifyERC20PermitSignature(data, signature);
      console.log('\nRecovered signer address:', recoveredAddress);
      console.log('Expected signer address:', signer.getSignerAddress());

      if (recoveredAddress.toLowerCase() === signer.getSignerAddress().toLowerCase()) {
        console.log('✅ Signature verification successful!');
      } else {
        console.log('❌ Signature verification failed!');
      }

      // 生成 cast 命令
      console.log('\nCast command for permit:');
      console.log(`cast send ${options.contractAddress} "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)" ${options.owner} ${options.spender} ${options.value} ${options.deadline} ${signature.v} ${signature.r} ${signature.s} --private-key <SPENDER_PRIVATE_KEY>`);

    } catch (error) {
      console.error('Error:', error);
      process.exit(1);
    }
  });

program
  .command('verify')
  .description('Verify a permitBuy signature')
  .requiredOption('-t, --token-id <id>', 'NFT token ID')
  .requiredOption('-b, --buyer <address>', 'Buyer address')
  .requiredOption('-p, --price <amount>', 'Price in wei')
  .requiredOption('-d, --deadline <timestamp>', 'Deadline timestamp')
  .requiredOption('-c, --chain-id <id>', 'Chain ID')
  .requiredOption('-a, --contract-address <address>', 'NFTMarket contract address')
  .requiredOption('-v, --v <v>', 'Signature v')
  .requiredOption('-r, --r <r>', 'Signature r')
  .requiredOption('-s, --s <s>', 'Signature s')
  .action(async (options) => {
    try {
      const signer = new NFTMarketSigner(
        '0x0000000000000000000000000000000000000000000000000000000000000000', // dummy key
        BigInt(options.chainId),
        options.contractAddress,
        options.domainName,
        options.domainVersion
      );

      const data: PermitBuyData = {
        tokenId: BigInt(options.tokenId),
        buyer: options.buyer,
        price: BigInt(options.price),
        deadline: BigInt(options.deadline)
      };

      const signature = {
        v: parseInt(options.v),
        r: options.r,
        s: options.s,
        signature: '' // not needed for verification
      };

      console.log('Verifying permitBuy signature...');
      console.log('Data:', {
        tokenId: data.tokenId.toString(),
        buyer: data.buyer,
        price: data.price.toString(),
        deadline: data.deadline.toString()
      });

      const recoveredAddress = signer.verifySignature(data, signature);
      console.log('Recovered signer address:', recoveredAddress);

    } catch (error) {
      console.error('Error:', error);
      process.exit(1);
    }
  });

program.parse();
