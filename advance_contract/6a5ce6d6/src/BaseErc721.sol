// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BaseERC721
 * @dev 一个最小化的 ERC721 合约，使用 OpenZeppelin 标准实现
 */
contract BaseERC721 is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    /**
     * @dev 铸造新的 NFT
     * @param to 接收者地址
     * @return tokenId 新铸造的 token ID
     */
    function mint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev 获取下一个 token ID
     */
    function getNextTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 获取总供应量
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }
}
