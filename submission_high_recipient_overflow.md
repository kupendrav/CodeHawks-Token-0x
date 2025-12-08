# Recipient Balance Overflow in `_transfer` Allows Balance Wrap-Around

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: Token transfers should revert if the recipient's balance would overflow, maintaining accounting integrity.
* **Specific Issue**: `_transfer` checks underflow for the sender (`if lt(fromAmount, value)`) but does NOT check overflow when adding to recipient's balance (`sstore(toSlot, add(toAmount, value))`). This allows recipient balance to wrap around.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _transfer(address from, address to, uint256 value) internal returns (bool success) {
        assembly ("memory-safe") {
            // ...
            if lt(fromAmount, value) {
                // Reverts on underflow - GOOD
                revert(...)
            }

            sstore(fromSlot, sub(fromAmount, value))
            sstore(toSlot, add(toAmount, value))    // @> No overflow check! Can wrap to small number
        }
    }
```

## Risk

**Likelihood**:

* **High**: Any transfer to a recipient with near-max balance triggers this. Attackers can set up whale accounts near `type(uint256).max`.

**Impact**:

* **High**: Recipient's balance wraps to a tiny number, effectively destroying their tokens while sender loses theirs legitimately.
* **Griefing/Theft**: Malicious actors can use this to grief large holders or manipulate DeFi positions.

## Proof of Concept

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
    function mint(address to, uint256 amount) public { _mint(to, amount); }
}

contract TransferRecipientOverflowTest is Test {
    Token token;
    address user1 = address(0x111);
    address user2 = address(0x222);

    function setUp() public {
        token = new Token();
    }

    function testRecipientOverflow() public {
        uint256 nearMax = type(uint256).max - 10;
        token.mint(user2, nearMax);
        token.mint(user1, 20);

        vm.prank(user1);
        token.transfer(user2, 20);

        // user2 balance wraps: (2^256 - 10) + 20 = 9
        assertEq(token.balanceOf(user2), 9);
        assertEq(token.balanceOf(user1), 0);
    }
}
```

## Recommended Mitigation

```diff
    function _transfer(address from, address to, uint256 value) internal returns (bool success) {
        assembly ("memory-safe") {
            // ...
            sstore(fromSlot, sub(fromAmount, value))
+           let newToAmount := add(toAmount, value)
+           if lt(newToAmount, toAmount) { revert(0, 0) } // Overflow check
-           sstore(toSlot, add(toAmount, value))
+           sstore(toSlot, newToAmount)
        }
    }
```
