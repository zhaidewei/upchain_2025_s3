// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KkErc20 is ERC20, Ownable {
    address public staking;

    modifier onlyStaking() {
        require(staking != address(0), "Staking not set");
        require(msg.sender == staking, "Only staking can mint and burn");
        _;
    }

    constructor() ERC20("KkToken", "KKT") Ownable(msg.sender) {}

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    function setStaking(address _staking) external onlyOwner {
        staking = _staking;
    }

    function mint(address to, uint256 amount) external onlyStaking {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyStaking {
        _burn(from, amount);
        emit Burn(from, amount);
    }
}
