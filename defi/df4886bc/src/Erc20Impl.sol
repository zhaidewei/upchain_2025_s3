// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Erc20Impl is ERC20 {
    // Invisible storage slots inherited from ERC20
    // mapping(address => uint256) _balances
    // mapping(address => mapping(address => uint256)) _allowances
    // uint256 _totalSupply
    // string _name
    // string _symbol
    uint256 public perMint;
    uint256 public price;
    address public factory;
    address public owner;
    address public implementation;
    bool public initialized;

    // Custom name and symbol storage
    string private _customName;
    string private _customSymbol;

    constructor() ERC20("", "") {}

    // Initialize function for proxy pattern
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _perMint,
        uint256 _price,
        address _factory,
        address _owner
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        // Set custom name and symbol
        _customName = tokenName;
        _customSymbol = tokenSymbol;

        perMint = _perMint;
        price = _price;
        factory = _factory;
        owner = _owner;
    }

    // Override name() and symbol() to use custom values
    function name() public view virtual override returns (string memory) {
        return _customName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _customSymbol;
    }

    // Mint function for the factory to call
    function mint(address to, uint256 amount) external {
        require(msg.sender == factory, "Only factory can mint");
        require(totalSupply() + amount <= type(uint256).max, "Would exceed max supply");
        _mint(to, amount);
    }

    // Buy meme tokens from Uniswap (no price comparison)
    function buyMeme(address router) external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");

        // Get WETH address from router
        address wethAddress = IUniswapV2Router02(router).WETH();

        // Calculate how many tokens we can get for the ETH sent
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = address(this);

        // Get the expected amount of tokens
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(msg.value, path);
        uint256 expectedTokens = amounts[1];

        // Swap ETH for tokens (no price comparison required)
        IUniswapV2Router02(router).swapExactETHForTokens{value: msg.value}(
            0, // min tokens (set to 0 to allow any slippage)
            path,
            msg.sender, // recipient
            block.timestamp + 1 hours
        );
    }
}
