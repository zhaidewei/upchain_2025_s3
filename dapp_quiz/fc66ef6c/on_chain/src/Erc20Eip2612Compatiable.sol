// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BaseErc20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 1_000_000_000 ether); // for test purpose, initial supply 1G DWT
    }
}

// https://eips.ethereum.org/EIPS/eip-2612
contract Erc20Eip2612Compatiable is BaseErc20 {
    mapping(address => uint256) public _nonces;
    string public version; // leave version to be filled by constructor

    constructor(string memory _version) BaseErc20("DeweiERC2612", "DToken") {
        version = _version;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        // Here the signature v r s is a EIP712 signature, we need to verify it using agreed data structure.
        bytes32 hash = keccak256(abi.encodePacked(
            hex"1901",
            DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                _nonces[owner]+1, // requester should use the next nonce, and starts from 1
                deadline))
        ));

        address recovered = ECDSA.recover(hash, v, r, s);
        require(recovered == owner, "Invalid signature");
        _approve(owner, spender, value);
        _nonces[owner]++;
    }

    function nonces(address user) external view returns (uint) {
        return _nonces[user];

    }
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name())),
            keccak256(bytes(version)),
            block.chainid,
            address(this)
        ));
    }
}
