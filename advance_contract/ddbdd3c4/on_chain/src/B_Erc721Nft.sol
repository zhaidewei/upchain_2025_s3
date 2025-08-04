// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Erc721Nft is ERC721 {
    constructor() ERC721("Erc721Nft", "ERC721Nft") {}
}
