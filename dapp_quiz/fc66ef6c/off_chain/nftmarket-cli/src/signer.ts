import { ethers } from 'ethers';
import { PermitBuyData, EIP712Domain, PermitBuySignature } from './types.js';

export class NFTMarketSigner {
  private domain: EIP712Domain;
  private privateKey: string;

  constructor(
    privateKey: string,
    chainId: bigint,
    contractAddress: string,
    domainName?: string,
    domainVersion?: string
  ) {
    this.privateKey = privateKey;
    this.domain = {
      name: domainName || 'DNFT', // 默认使用 DNFT，与合约部署时一致
      version: domainVersion || '1.0',
      chainId,
      verifyingContract: contractAddress
    };
  }

  /**
   * 创建 PermitBuy 的 EIP712 签名
   */
  async signPermitBuy(data: PermitBuyData): Promise<PermitBuySignature> {
    const wallet = new ethers.Wallet(this.privateKey);

    // EIP712 类型定义
    const types = {
      PermitBuy: [
        { name: 'tokenId', type: 'uint256' },
        { name: 'buyer', type: 'address' },
        { name: 'price', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
      ]
    };

    // 创建签名
    const signature = await wallet.signTypedData(this.domain, types, data);

    // 解析签名
    const sig = ethers.Signature.from(signature);

    return {
      v: sig.v,
      r: sig.r,
      s: sig.s,
      signature
    };
  }

  /**
   * 验证签名
   */
  verifySignature(data: PermitBuyData, signature: PermitBuySignature): string {
    const types = {
      PermitBuy: [
        { name: 'tokenId', type: 'uint256' },
        { name: 'buyer', type: 'address' },
        { name: 'price', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
      ]
    };

    const recoveredAddress = ethers.verifyTypedData(
      this.domain,
      types,
      data,
      signature.signature
    );

    return recoveredAddress;
  }

  /**
   * 获取签名者地址
   */
  getSignerAddress(): string {
    const wallet = new ethers.Wallet(this.privateKey);
    return wallet.address;
  }
}
