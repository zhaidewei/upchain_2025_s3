export interface PermitBuyData {
  tokenId: bigint;
  buyer: string;
  price: bigint;
  deadline: bigint;
}

export interface EIP712Domain {
  name: string;
  version: string;
  chainId: bigint;
  verifyingContract: string;
}

export interface PermitBuySignature {
  v: number;
  r: string;
  s: string;
  signature: string;
}
