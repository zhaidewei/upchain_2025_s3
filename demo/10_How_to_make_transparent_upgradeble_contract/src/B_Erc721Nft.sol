// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Erc721Nft is ERC721Upgradeable {
    // State variables for upgradeable ERC721
    string private _name;
    string private _symbol;
    bool private _initialized;

    // Events
    event Erc721NftInitialized(string name, string symbol);

    constructor() ERC721("", "") {
        // Constructor is not used in proxy pattern, but required by inheritance
    }

    /**
     * @dev Initialize the contract for proxy deployment
     */
    function initialize(string memory name_, string memory symbol_) public {
        require(!_initialized, "Already initialized");
        require(msg.sender == address(this), "Only callable by proxy");

        _name = name_;
        _symbol = symbol_;
        _initialized = true;

        emit Erc721NftInitialized(name_, symbol_);
    }

    /**
     * @dev Override name() to use state variable instead of immutable
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Override symbol() to use state variable instead of immutable
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Mint function for admin to mint NFTs
     */
    function mint(address to, uint256 tokenId) public {
        require(_initialized, "Contract not initialized");
        _mint(to, tokenId);
    }

    /**
     * @dev Check if contract is initialized
     */
    function isInitialized() public view returns (bool) {
        return _initialized;
    }
}
