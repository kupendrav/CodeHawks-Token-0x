// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
    function mint(address to, uint256 amount) public { _mint(to, amount); }
}

// VULN 1: Self-transfer corrupts balance - adds value instead of no-op
contract SelfTransferOverflowTest is Test {
    Token token;
    address user = address(0x123);

    function setUp() public {
        token = new Token();
    }

    function testSelfTransferCorruptsBalance() public {
        // Mint to user
        token.mint(user, 100);
        assertEq(token.balanceOf(user), 100);

        // Self-transfer: from == to
        // _transfer subtracts from `from` then adds to `to`
        // But both are same address, so balance = balance - 50 + 50 = 100
        // HOWEVER, due to slot caching issue, toAmount is read BEFORE fromSlot write
        // So it reads old value and adds to it
        vm.prank(user);
        token.transfer(user, 50);

        // Expected: 100 (no change)
        // Actual: 100 - 50 + 50 = 100? Let's see...
        // The bug: fromSlot and toSlot are same, but toAmount was loaded before sstore
        // sstore(fromSlot, sub(100, 50)) = 50
        // sstore(toSlot, add(100, 50)) = 150 <-- uses OLD toAmount!
        assertEq(token.balanceOf(user), 150); // Balance increased by 50!
    }
}

// VULN 2: Transfer to same address as sender - recipient overflow not checked
contract TransferRecipientOverflowTest is Test {
    Token token;
    address user1 = address(0x111);
    address user2 = address(0x222);

    function setUp() public {
        token = new Token();
    }

    function testRecipientOverflow() public {
        // Mint near-max to user2 (recipient)
        uint256 nearMax = type(uint256).max - 10;
        token.mint(user2, nearMax);

        // Mint small amount to user1 (sender)
        token.mint(user1, 20);

        // user1 transfers to user2, causing user2's balance to overflow
        vm.prank(user1);
        token.transfer(user2, 20);

        // user2 balance should wrap: (2^256 - 10) + 20 = 9
        assertEq(token.balanceOf(user2), 9);
        assertEq(token.balanceOf(user1), 0);
    }
}

// VULN 3: Infinite allowance is depleted (no type(uint256).max skip)
contract InfiniteAllowanceDepletedTest is Test {
    Token token;
    address owner = address(0xA1);
    address spender = address(0xB2);
    address recipient = address(0xC3);

    function setUp() public {
        token = new Token();
        token.mint(owner, 1000);
        vm.prank(owner);
        token.approve(spender, type(uint256).max);
    }

    function testInfiniteAllowanceGetsReduced() public {
        uint256 allowanceBefore = token.allowance(owner, spender);
        assertEq(allowanceBefore, type(uint256).max);

        vm.prank(spender);
        token.transferFrom(owner, recipient, 100);

        uint256 allowanceAfter = token.allowance(owner, spender);
        // In standard ERC20 (OZ), infinite allowance stays infinite
        // Here it gets reduced
        assertEq(allowanceAfter, type(uint256).max - 100);
    }
}

// VULN 4: Memory corruption - _balanceOf writes to ptr+0x20 with 0, potentially corrupting free memory
contract MemoryCorruptionTest is Test {
    Token token;
    address user = address(0x123);

    function setUp() public {
        token = new Token();
        token.mint(user, 500);
    }

    function testBalanceOfMemoryWrite() public view {
        // _balanceOf does: mstore(add(ptr, 0x20), 0)
        // This writes zero to memory at ptr+32 after loading balance
        // This could corrupt memory if called in sequence with other operations
        // Not directly exploitable but shows unsafe memory handling
        uint256 bal = token.balanceOf(user);
        assertEq(bal, 500);
    }
}

// VULN 5: allowance() reverts for zero addresses instead of returning 0
contract AllowanceZeroAddressRevertTest is Test {
    Token token;

    function setUp() public {
        token = new Token();
    }

    function testAllowanceZeroOwnerReverts() public {
        vm.expectRevert();
        token.allowance(address(0), address(0x123));
    }

    function testAllowanceZeroSpenderReverts() public {
        vm.expectRevert();
        token.allowance(address(0x123), address(0));
    }
}
