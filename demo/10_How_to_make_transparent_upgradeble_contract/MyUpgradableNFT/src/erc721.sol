// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721URIStorageUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Erc721Nft is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public tokenIdCounter; // not a standard element

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    // This function is called by many upgrade function. It make sure if not called by Owner,
    // then it fails. It is like centralize the checks to one place.

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // initializer is a modifier that guarentee the function is only called once.
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        tokenIdCounter = 1;
    }

    function mint(address to, string memory uri) public onlyOwner {
        _mint(to, tokenIdCounter);
        _setTokenURI(tokenIdCounter, uri);
        tokenIdCounter++;
    }
}
