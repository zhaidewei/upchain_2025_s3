// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {BaseERC721} from "../src/BaseErc721.sol";

contract BaseERC721Test is Test {
    BaseERC721 public nft;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        nft = new BaseERC721("MyNFT", "MNFT");
        vm.stopPrank();
    }

    function test_Constructor() public view {
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.getNextTokenId(), 0);
    }

    function test_Mint() public {
        vm.startPrank(owner);

        uint256 tokenId = nft.mint(user1);
        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.getNextTokenId(), 1);

        tokenId = nft.mint(user2);
        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.totalSupply(), 2);
        assertEq(nft.getNextTokenId(), 2);

        vm.stopPrank();
    }

    function test_MintToZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("ERC721InvalidReceiver(0x0000000000000000000000000000000000000000)");
        nft.mint(address(0));
        vm.stopPrank();
    }

    function test_MintNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("OwnableUnauthorizedAccount(0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF)");
        nft.mint(user2);
        vm.stopPrank();
    }

    function test_Transfer() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.transferFrom(user1, user2, tokenId);
        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
        vm.stopPrank();
    }

    function test_ApproveAndTransfer() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.approve(user2, tokenId);
        vm.stopPrank();

        vm.startPrank(user2);
        nft.transferFrom(user1, user2, tokenId);
        assertEq(nft.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function test_SetApprovalForAll() public {
        vm.startPrank(owner);
        uint256 tokenId1 = nft.mint(user1);
        uint256 tokenId2 = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.setApprovalForAll(user2, true);
        vm.stopPrank();

        vm.startPrank(user2);
        nft.transferFrom(user1, user2, tokenId1);
        nft.transferFrom(user1, user2, tokenId2);
        assertEq(nft.ownerOf(tokenId1), user2);
        assertEq(nft.ownerOf(tokenId2), user2);
        vm.stopPrank();
    }

    function test_SafeTransferFrom() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.safeTransferFrom(user1, user2, tokenId);
        assertEq(nft.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function test_SafeTransferFromWithData() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.safeTransferFrom(user1, user2, tokenId, "0x1234");
        assertEq(nft.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function test_GetApproved() public {
        vm.startPrank(owner);
        nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.approve(user2, 0);
        assertEq(nft.getApproved(0), user2);
        vm.stopPrank();
    }

    function test_IsApprovedForAll() public {
        vm.startPrank(owner);
        nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        assertEq(nft.isApprovedForAll(user1, user2), false);
        nft.setApprovalForAll(user2, true);
        assertEq(nft.isApprovedForAll(user1, user2), true);
        nft.setApprovalForAll(user2, false);
        assertEq(nft.isApprovedForAll(user1, user2), false);
        vm.stopPrank();
    }

    function test_TransferToSelf() public {
        vm.startPrank(owner);
        nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        // OpenZeppelin 允许自己给自己授权，所以这个测试应该通过
        nft.approve(user1, 0);
        assertEq(nft.getApproved(0), user1);
        vm.stopPrank();
    }

    function test_ApproveToCaller() public {
        vm.startPrank(owner);
        nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        // OpenZeppelin 允许自己给自己设置操作员权限，所以这个测试应该通过
        nft.setApprovalForAll(user1, true);
        assertEq(nft.isApprovedForAll(user1, user1), true);
        vm.stopPrank();
    }

    function test_TransferFromNotOwner() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("ERC721InsufficientApproval(0x537C8f3d3E18dF5517a58B3fB9D9143697996802, 0)");
        nft.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
    }

    function test_TransferFromNotApproved() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("ERC721InsufficientApproval(0x537C8f3d3E18dF5517a58B3fB9D9143697996802, 0)");
        nft.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
    }

    function test_TransferToZeroAddress() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("ERC721InvalidReceiver(0x0000000000000000000000000000000000000000)");
        nft.transferFrom(user1, address(0), tokenId);
        vm.stopPrank();
    }

    function test_TransferFromIncorrectOwner() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("ERC721InsufficientApproval(0x537C8f3d3E18dF5517a58B3fB9D9143697996802, 0)");
        nft.transferFrom(user2, user1, tokenId);
        vm.stopPrank();
    }

    function test_BalanceOfZeroAddress() public {
        vm.expectRevert("ERC721InvalidOwner(0x0000000000000000000000000000000000000000)");
        nft.balanceOf(address(0));
    }

    function test_OwnerOfNonexistentToken() public {
        vm.expectRevert("ERC721NonexistentToken(999)");
        nft.ownerOf(999);
    }

    function test_GetApprovedNonexistentToken() public {
        vm.expectRevert("ERC721NonexistentToken(999)");
        nft.getApproved(999);
    }

    function test_TokenURI() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        // 默认情况下，tokenURI 应该返回空字符串
        assertEq(nft.tokenURI(tokenId), "");
    }

    function test_TokenURINonexistent() public {
        vm.expectRevert("ERC721NonexistentToken(999)");
        nft.tokenURI(999);
    }

    function test_MultipleMints() public {
        vm.startPrank(owner);

        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = nft.mint(user1);
            assertEq(tokenId, i);
            assertEq(nft.ownerOf(tokenId), user1);
        }

        assertEq(nft.balanceOf(user1), 10);
        assertEq(nft.totalSupply(), 10);
        assertEq(nft.getNextTokenId(), 10);

        vm.stopPrank();
    }

    function test_TransferClearsApproval() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        nft.approve(user2, tokenId);
        assertEq(nft.getApproved(tokenId), user2);
        nft.transferFrom(user1, user2, tokenId);
        assertEq(nft.getApproved(tokenId), address(0));
        vm.stopPrank();
    }
}
