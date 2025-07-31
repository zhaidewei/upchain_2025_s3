// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Erc20Eip2612Compatiable} from "../src/Erc20Eip2612Compatiable.sol";

contract Erc20Eip2612CompatiableTest is Test {
    Erc20Eip2612Compatiable public token;

    // Test accounts
    address public deployer = address(1);
    address public spender = address(3);

    // Private key for owner (for signing)
    uint256 private ownerPrivateKey = 0xA11CE;
    address public owner;

    function setUp() public {
        // Set owner's address based on private key
        owner = vm.addr(ownerPrivateKey);

        vm.startPrank(deployer);
        token = new Erc20Eip2612Compatiable("1");

        // Transfer some tokens to owner for testing
        require(token.transfer(owner, 1000), "Transfer failed");
        vm.stopPrank();
    }

    function test_BasicERC20Functionality() public {
        assertEq(token.name(), "DeweiERC2612");
        assertEq(token.symbol(), "DToken");

        assertEq(token.balanceOf(deployer), 1000 ether - 1000);
        assertEq(token.balanceOf(owner), 1000);
    }

    function test_DomainSeparator() public {
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(token.name())),
                keccak256(bytes(token.version())),
                block.chainid,
                address(token)
            )
        );

        assertEq(token.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    function test_Nonces() public {
        assertEq(token.nonces(owner), 0);
    }

    function test_Permit() public {
        console.log("Owner address:", owner);
        console.log("Owner balance:", token.balanceOf(owner));

        uint256 value = 100;
        uint256 deadline = block.timestamp + 3600; // 1 hour from now
        uint256 nonce = token.nonces(owner);
        console.log("Current Nonce:", nonce);

        // Create the hash exactly as the contract does - use current nonce
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"1901",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce, // Use current nonce as expected by contract
                        deadline
                    )
                )
            )
        );

        // Sign the hash with owner's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // Before permit
        assertEq(token.allowance(owner, spender), 0);

        // Execute permit
        token.permit(owner, spender, value, deadline, v, r, s);

        // After permit
        console.log("Allowance after permit:", token.allowance(owner, spender));
        console.log("Nonce after permit:", token.nonces(owner));

        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), 1);
    }

    function test_PermitAndTransferFrom() public {
        uint256 value = 100;
        uint256 deadline = block.timestamp + 3600; // 1 hour from now
        uint256 nonce = token.nonces(owner);

        // Create the hash exactly as the contract does - use current nonce
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"1901",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce, // Use current nonce as expected by contract
                        deadline
                    )
                )
            )
        );

        // Sign the hash with owner's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // Execute permit
        token.permit(owner, spender, value, deadline, v, r, s);

        // Use transferFrom with the approved allowance
        vm.prank(spender);
        require(token.transferFrom(owner, spender, 50), "TransferFrom failed");

        // Check balances after transfer
        assertEq(token.balanceOf(owner), 1000 - 50);
        assertEq(token.balanceOf(spender), 50);
        assertEq(token.allowance(owner, spender), 50); // Remaining allowance
    }

    function test_RevertWhen_ExpiredPermit() public {
        uint256 value = 100;
        uint256 deadline = block.timestamp - 1; // Expired deadline
        uint256 nonce = token.nonces(owner);

        // Create the hash exactly as the contract does - use current nonce
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"1901",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce, // Use current nonce as expected by contract
                        deadline
                    )
                )
            )
        );

        // Sign the hash with owner's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        // This should fail due to expired deadline
        vm.expectRevert("ERC20Permit: expired deadline");
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function test_RevertWhen_InvalidSignature() public {
        uint256 value = 100;
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.nonces(owner);

        // Create the hash exactly as the contract does - use current nonce
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"1901",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce, // Use current nonce as expected by contract
                        deadline
                    )
                )
            )
        );

        // Sign with a different private key
        uint256 wrongPrivateKey = 0xB0B;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, hash);

        // This should fail due to invalid signature
        vm.expectRevert("Invalid signature");
        token.permit(owner, spender, value, deadline, v, r, s);
    }
}
