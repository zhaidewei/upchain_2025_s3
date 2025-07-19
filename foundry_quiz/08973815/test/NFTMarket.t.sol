// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/ExtendedERC20WithData.sol";
import "../src/BaseERC721.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    ExtendedERC20WithData public paymentToken;
    BaseERC721 public nft;

    address public owner = address(this);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public charlie = address(0x4);

    uint256 public constant TOKEN_ID_1 = 1;
    uint256 public constant TOKEN_ID_2 = 2;
    uint256 public constant LISTING_PRICE = 100 * 10**18; // 100 tokens

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    function setUp() public {
        // Deploy contracts
        paymentToken = new ExtendedERC20WithData();
        nft = new BaseERC721("TestNFT", "TNFT", "https://test.com/");
        market = new NFTMarket(address(paymentToken), address(nft));

        // Mint NFTs to alice
        vm.startPrank(alice);
        nft.mint(alice, TOKEN_ID_1);
        nft.mint(alice, TOKEN_ID_2);

        // Approve market to transfer specific NFTs
        nft.approve(address(market), TOKEN_ID_1);
        nft.approve(address(market), TOKEN_ID_2);
        vm.stopPrank();

        // Give tokens to bob and charlie
        paymentToken.transfer(bob, 10000 * 10**18);
        paymentToken.transfer(charlie, 10000 * 10**18);
    }

    // ============= 上架NFT测试 =============

    function test_List_Success() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        (address seller, uint256 price, bool active) = market.listings(TOKEN_ID_1);
        assertEq(seller, alice);
        assertEq(price, LISTING_PRICE);
        assertTrue(active);
    }

    function test_List_EmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit NFTListed(TOKEN_ID_1, alice, LISTING_PRICE);
        market.list(TOKEN_ID_1, LISTING_PRICE);
    }

    function test_List_ZeroPrice_Reverts() public {
        vm.prank(alice);
        vm.expectRevert("Price must be greater than 0");
        market.list(TOKEN_ID_1, 0);
    }

    function test_List_NotOwner_Reverts() public {
        vm.prank(bob);
        vm.expectRevert("You don't own this NFT");
        market.list(TOKEN_ID_1, LISTING_PRICE);
    }

    function test_List_NotApproved_Reverts() public {
        // Mint a new NFT that's not approved
        uint256 unapprovedTokenId = 99;
        vm.prank(alice);
        nft.mint(alice, unapprovedTokenId);

        vm.prank(alice);
        vm.expectRevert("NFT not approved to market");
        market.list(unapprovedTokenId, LISTING_PRICE);
    }

    function test_List_AlreadyListed_Reverts() public {
        vm.startPrank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        vm.expectRevert("NFT already listed");
        market.list(TOKEN_ID_1, LISTING_PRICE * 2);
        vm.stopPrank();
    }

    // ============= 购买NFT测试 =============

    function test_BuyNft_Success() public {
        // List NFT
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        // Bob approves and buys
        vm.startPrank(bob);
        paymentToken.approve(address(market), LISTING_PRICE);
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();

        // Check ownership changed
        assertEq(nft.ownerOf(TOKEN_ID_1), bob);

        // Check listing is inactive
        (,, bool active) = market.listings(TOKEN_ID_1);
        assertFalse(active);

        // Check token balances
        assertEq(paymentToken.balanceOf(alice), LISTING_PRICE);
        assertEq(paymentToken.balanceOf(bob), 10000 * 10**18 - LISTING_PRICE);
    }

    function test_BuyNft_EmitsEvent() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        vm.startPrank(bob);
        paymentToken.approve(address(market), LISTING_PRICE);

        vm.expectEmit(true, true, true, true);
        emit NFTSold(TOKEN_ID_1, alice, bob, LISTING_PRICE);
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_BuyNft_SelfPurchase_Reverts() public {
        vm.startPrank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        vm.expectRevert("Cannot buy your own NFT");
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_BuyNft_NotListed_Reverts() public {
        vm.startPrank(bob);
        paymentToken.approve(address(market), LISTING_PRICE);

        vm.expectRevert("NFT not listed");
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_BuyNft_DoublePurchase_Reverts() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        // First purchase by Bob
        vm.startPrank(bob);
        paymentToken.approve(address(market), LISTING_PRICE);
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();

        // Second purchase attempt by Charlie should fail
        vm.startPrank(charlie);
        paymentToken.approve(address(market), LISTING_PRICE);

        vm.expectRevert("NFT not listed");
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_BuyNft_InsufficientApproval_Reverts() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        vm.startPrank(bob);
        paymentToken.approve(address(market), LISTING_PRICE - 1); // Insufficient approval

        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_BuyNft_InsufficientBalance_Reverts() public {
        // Create a user with insufficient balance
        address poorUser = address(0x999);
        paymentToken.transfer(poorUser, 50 * 10**18); // Less than listing price

        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        vm.startPrank(poorUser);
        paymentToken.approve(address(market), LISTING_PRICE);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();
    }

    // ============= TransferWithCallback 购买测试 =============

    function test_TokensReceived_Success() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        bytes memory data = abi.encode(TOKEN_ID_1);

        vm.prank(bob);
        paymentToken.transferWithCallback(address(market), LISTING_PRICE, data);

        // Check ownership changed
        assertEq(nft.ownerOf(TOKEN_ID_1), bob);

        // Check listing is inactive
        (,, bool active) = market.listings(TOKEN_ID_1);
        assertFalse(active);

        // Check token balances
        assertEq(paymentToken.balanceOf(alice), LISTING_PRICE);
        assertEq(paymentToken.balanceOf(bob), 10000 * 10**18 - LISTING_PRICE);
    }

    function test_TokensReceived_OverPayment_Success() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        uint256 overPayment = LISTING_PRICE + 50 * 10**18;
        bytes memory data = abi.encode(TOKEN_ID_1);

        vm.prank(bob);
        paymentToken.transferWithCallback(address(market), overPayment, data);

        // Check seller gets the overpayment
        assertEq(paymentToken.balanceOf(alice), overPayment);
        assertEq(nft.ownerOf(TOKEN_ID_1), bob);
    }

    function test_TokensReceived_UnderPayment_Reverts() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        uint256 underPayment = LISTING_PRICE - 1;
        bytes memory data = abi.encode(TOKEN_ID_1);

        vm.prank(bob);
        vm.expectRevert("Incorrect payment amount");
        paymentToken.transferWithCallback(address(market), underPayment, data);
    }

    function test_TokensReceived_WrongToken_Reverts() public {
        // Create another ERC20 token
        ExtendedERC20WithData wrongToken = new ExtendedERC20WithData();
        wrongToken.transfer(bob, 1000 * 10**18);

        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        bytes memory data = abi.encode(TOKEN_ID_1);

        vm.prank(bob);
        vm.expectRevert("Only accept calls from payment token");
        wrongToken.transferWithCallback(address(market), LISTING_PRICE, data);
    }

    function test_TokensReceived_InvalidData_Reverts() public {
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        bytes memory invalidData = "short"; // Less than 32 bytes

        vm.prank(bob);
        vm.expectRevert("Invalid data length");
        paymentToken.transferWithCallback(address(market), LISTING_PRICE, invalidData);
    }

    // ============= 模糊测试 (0.01-10000 Token) =============

    function testFuzz_ListAndBuy_RandomPrice(uint256 price) public {
        // Restrict price to 0.01-10000 tokens
        vm.assume(price >= 0.01 * 10**18 && price <= 10000 * 10**18);
        vm.assume(price <= paymentToken.balanceOf(bob)); // Ensure bob has enough tokens

        // List NFT with random price
        vm.prank(alice);
        market.list(TOKEN_ID_1, price);

        // Buy with Bob
        vm.startPrank(bob);
        paymentToken.approve(address(market), price);
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();

        // Verify purchase
        assertEq(nft.ownerOf(TOKEN_ID_1), bob);
        assertEq(paymentToken.balanceOf(alice), price);

        // Check listing is inactive
        (,, bool active) = market.listings(TOKEN_ID_1);
        assertFalse(active);
    }

    function testFuzz_ListAndBuy_RandomBuyer(address buyer, uint256 price) public {
        // Assumptions
        vm.assume(buyer != address(0) && buyer != alice && buyer != address(market));
        vm.assume(price >= 0.01 * 10**18 && price <= 1000 * 10**18);
        vm.assume(buyer.code.length == 0); // Ensure it's an EOA

        // Give tokens to random buyer
        paymentToken.transfer(buyer, price + 1000 * 10**18);

        // List NFT (TOKEN_ID_1 is already approved in setUp)
        vm.prank(alice);
        market.list(TOKEN_ID_1, price);

        // Random buyer purchases
        vm.startPrank(buyer);
        paymentToken.approve(address(market), price);
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();

        // Verify
        assertEq(nft.ownerOf(TOKEN_ID_1), buyer);
        assertEq(paymentToken.balanceOf(alice), price);
    }

    // ============= 不可变测试：NFTMarket 永远不持有 Token =============

    function invariant_MarketNeverHoldsTokens() public {
        assertEq(paymentToken.balanceOf(address(market)), 0, "Market should never hold tokens");
    }

    function test_Invariant_AfterDirectTransfer() public {
        // Even if someone directly transfers tokens to market, it should not affect operations
        paymentToken.transfer(address(market), 1000 * 10**18);

        // List and buy should still work
        vm.prank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);

        vm.startPrank(bob);
        paymentToken.approve(address(market), LISTING_PRICE);
        market.buyNft(TOKEN_ID_1);
        vm.stopPrank();

        // Check that the direct transfer doesn't affect the purchase
        assertEq(nft.ownerOf(TOKEN_ID_1), bob);
        assertEq(paymentToken.balanceOf(alice), LISTING_PRICE);

        // Market should still have the directly transferred tokens (this is expected)
        assertEq(paymentToken.balanceOf(address(market)), 1000 * 10**18);
    }

    function test_Invariant_MultipleTransactions() public {
        // List multiple NFTs
        vm.startPrank(alice);
        market.list(TOKEN_ID_1, LISTING_PRICE);
        market.list(TOKEN_ID_2, LISTING_PRICE * 2);
        vm.stopPrank();

        // Buy first NFT with callback
        bytes memory data1 = abi.encode(TOKEN_ID_1);
        vm.prank(bob);
        paymentToken.transferWithCallback(address(market), LISTING_PRICE, data1);

        // Buy second NFT with regular method
        vm.startPrank(charlie);
        paymentToken.approve(address(market), LISTING_PRICE * 2);
        market.buyNft(TOKEN_ID_2);
        vm.stopPrank();

        // Market should not hold any tokens
        assertEq(paymentToken.balanceOf(address(market)), 0);

        // Verify all transfers
        assertEq(nft.ownerOf(TOKEN_ID_1), bob);
        assertEq(nft.ownerOf(TOKEN_ID_2), charlie);
        assertEq(paymentToken.balanceOf(alice), LISTING_PRICE + LISTING_PRICE * 2);
    }
}
