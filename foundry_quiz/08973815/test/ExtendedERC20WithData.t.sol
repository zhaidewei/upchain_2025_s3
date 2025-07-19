// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/ExtendedERC20WithData.sol";
import "../src/Interfaces.sol";

contract ExtendedERC20WithDataTest is Test {
    ExtendedERC20WithData public token;
    MockTokenReceiver public mockReceiver;
    MockRevertingReceiver public revertingReceiver;

    address public owner = address(this);
    address public alice = address(0x2);
    address public bob = address(0x3);

    function setUp() public {
        token = new ExtendedERC20WithData();
        mockReceiver = new MockTokenReceiver();
        revertingReceiver = new MockRevertingReceiver();
    }

    function test_InitialState() public {
        assertEq(token.name(), "ExtendedToken");
        assertEq(token.symbol(), "EXT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 10**7 * 10**18);
        assertEq(token.balanceOf(address(this)), 10**7 * 10**18);
    }

    function test_TransferWithCallback_Success() public {
        uint256 transferAmount = 1000 * 10**18;
        bytes memory data = abi.encode(uint256(123)); // tokenId

        bool success = token.transferWithCallback(address(mockReceiver), transferAmount, data);

        assertTrue(success);
        assertEq(token.balanceOf(address(mockReceiver)), transferAmount);
        assertEq(token.balanceOf(address(this)), token.totalSupply() - transferAmount);

        // Check callback was called
        assertEq(mockReceiver.lastFrom(), address(this));
        assertEq(mockReceiver.lastAmount(), transferAmount);
        assertEq(mockReceiver.lastData(), data);
    }

    function test_TransferWithCallback_EmitsEvent() public {
        uint256 transferAmount = 1000 * 10**18;
        bytes memory data = abi.encode(uint256(123));

        vm.expectEmit(true, true, false, true);
        emit ExtendedERC20WithData.TransferWithCallbackAndData(address(this), address(mockReceiver), transferAmount, data);

        token.transferWithCallback(address(mockReceiver), transferAmount, data);
    }

    function test_TransferWithCallback_InsufficientBalance() public {
        uint256 transferAmount = token.totalSupply() + 1;
        bytes memory data = abi.encode(uint256(123));

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transferWithCallback(address(mockReceiver), transferAmount, data);
    }

    function test_TransferWithCallback_ToEOA_Reverts() public {
        uint256 transferAmount = 1000 * 10**18;
        bytes memory data = abi.encode(uint256(123));

        vm.expectRevert("Cannot transfer to EOA");
        token.transferWithCallback(alice, transferAmount, data);
    }

    function test_TransferWithCallback_ReceiverReverts() public {
        uint256 transferAmount = 1000 * 10**18;
        bytes memory data = abi.encode(uint256(123));

        // Should revert when receiver reverts
        vm.expectRevert("Mock receiver revert");
        token.transferWithCallback(address(revertingReceiver), transferAmount, data);

        // Balance should remain unchanged
        assertEq(token.balanceOf(address(this)), token.totalSupply());
        assertEq(token.balanceOf(address(revertingReceiver)), 0);
    }

    function test_TransferWithCallback_ZeroAmount() public {
        bytes memory data = abi.encode(uint256(123));

        bool success = token.transferWithCallback(address(mockReceiver), 0, data);

        assertTrue(success);
        assertEq(mockReceiver.lastAmount(), 0);
    }

    function test_TransferWithCallback_EmptyData() public {
        uint256 transferAmount = 1000 * 10**18;
        bytes memory data = "";

        bool success = token.transferWithCallback(address(mockReceiver), transferAmount, data);

        assertTrue(success);
        assertEq(mockReceiver.lastData(), data);
    }

    function test_TransferWithCallback_LargeData() public {
        uint256 transferAmount = 1000 * 10**18;
        bytes memory data = abi.encode(uint256(123), "test string", address(alice));

        bool success = token.transferWithCallback(address(mockReceiver), transferAmount, data);

        assertTrue(success);
        assertEq(mockReceiver.lastData(), data);
    }

    // Fuzz testing
    function testFuzz_TransferWithCallback(uint256 amount, uint256 tokenId) public {
        vm.assume(amount <= token.totalSupply());

        bytes memory data = abi.encode(tokenId);

        bool success = token.transferWithCallback(address(mockReceiver), amount, data);

        assertTrue(success);
        assertEq(token.balanceOf(address(mockReceiver)), amount);
        assertEq(mockReceiver.lastAmount(), amount);

        (uint256 decodedTokenId) = abi.decode(mockReceiver.lastData(), (uint256));
        assertEq(decodedTokenId, tokenId);
    }
}

// Mock contract that implements ITokenReceiverWithData
contract MockTokenReceiver is ITokenReceiverWithData {
    address public lastFrom;
    uint256 public lastAmount;
    bytes public lastData;

    function tokensReceived(address from, uint256 amount, bytes calldata data) external {
        lastFrom = from;
        lastAmount = amount;
        lastData = data;
    }
}

// Mock contract that always reverts
contract MockRevertingReceiver is ITokenReceiverWithData {
    function tokensReceived(address, uint256, bytes calldata) external pure {
        revert("Mock receiver revert");
    }
}
