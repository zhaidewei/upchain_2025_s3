// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Erc20Impl} from "./Erc20Impl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
    using Clones for address;

    address public immutable ERC20_IMPLEMENTATION;
    address[] public allMemes;

    // Fee distribution: 1% to project, 99% to meme creator
    uint8 public constant PROJECT_FEE_PERCENTAGE = 1;
    uint8 public constant CREATOR_FEE_PERCENTAGE = 99;
    uint8 public constant FEE_DENOMINATOR = 100;

    constructor(address _erc20Implementation) Ownable(msg.sender) {
        ERC20_IMPLEMENTATION = _erc20Implementation;
    }

    function deployMeme(string memory name, string memory symbol, uint256 perMint, uint256 price)
        external
        returns (address memeAddress)
    {
        memeAddress = ERC20_IMPLEMENTATION.clone();
        Erc20Impl(memeAddress).initialize(name, symbol, perMint, price, address(this), msg.sender);
        allMemes.push(memeAddress);
        return memeAddress;
    }

    function mintMeme(address tokenAddr) external payable {
        Erc20Impl token = Erc20Impl(tokenAddr);

        // Verify the token was created by this factory
        require(token.factory() == address(this), "Token not from this factory");

        // Check if payment matches the price
        require(msg.value == token.price(), "Incorrect payment amount");

        // Check if minting would exceed total supply
        require(token.totalSupply() + token.perMint() <= type(uint256).max, "Would exceed max supply");

        // Mint tokens to the caller
        token.mint(msg.sender);

        // Distribute fees
        uint256 projectFee = (msg.value * PROJECT_FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 creatorFee = msg.value - projectFee;

        // Send fees
        (bool projectFeeSent,) = owner().call{value: projectFee}("");
        require(projectFeeSent, "Failed to send project fee");

        (bool creatorFeeSent,) = token.owner().call{value: creatorFee}("");
        require(creatorFeeSent, "Failed to send creator fee");
    }

    function getAllMemes() external view returns (address[] memory) {
        return allMemes;
    }
}
