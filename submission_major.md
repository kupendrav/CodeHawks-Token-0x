# `_mint` arithmetic overflow corrupts `totalSupply` and balances, enabling wrap-around exploits

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: ERC20 implementations must ensure minting cannot overflow `totalSupply` or account balances. Overflows break core invariants and allow supply/balance wrap-around.
* **Specific Issue**: `Token-0x` uses inline assembly in `_mint` to `add(supply, value)` and `add(accountBalance, value)` without overflow checks. This allows supply and balances to wrap modulo 2^256.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _mint(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ...
            let supply := sload(supplySlot)
            sstore(supplySlot, add(supply, value)) // @> No overflow check on totalSupply
            // ...
            let accountBalance := sload(accountBalanceSlot)
            sstore(accountBalanceSlot, add(accountBalance, value)) // @> No overflow check on balance
        }
    }
```

## Risk

**Likelihood**:

* **High**: Many inheriting tokens expose `mint` (owner/minter roles, reward emissions, etc.). Any call path that reaches `_mint` can trigger the overflow.

**Impact**:

* **High**: `totalSupply` and user balances can wrap, breaking accounting (e.g., large mint followed by small mint collapses supply to a tiny number). Protocols relying on supply/balance correctness are compromised.
* **Economic Manipulation**: Attackers can craft wrap-around states to bypass checks based on supply/balance magnitudes.

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

contract MintOverflowTest is Test {
    Token token;
    address user = address(0x123);

    function setUp() public {
        token = new Token();
    }

    function testTotalSupplyOverflow() public {
        uint256 nearMax = type(uint256).max - 10;
        token.mint(user, nearMax);
        assertEq(token.totalSupply(), nearMax);
        assertEq(token.balanceOf(user), nearMax);

        token.mint(user, 20);
        // Wraps: (2^256 - 10) + 20 = 9 (mod 2^256)
        assertEq(token.totalSupply(), 9);
        assertEq(token.balanceOf(user), 9);
    }
}
```

## Recommended Mitigation

Add overflow checks in `_mint` (and similarly in `_transfer` for recipient additions):

```diff
    function _mint(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ...
            let supply := sload(supplySlot)
+           let newSupply := add(supply, value)
+           if lt(newSupply, supply) { revert(0, 0) }
-           sstore(supplySlot, add(supply, value))
+           sstore(supplySlot, newSupply)

            // ...
            let accountBalance := sload(accountBalanceSlot)
+           let newBalance := add(accountBalance, value)
+           if lt(newBalance, accountBalance) { revert(0, 0) }
-           sstore(accountBalanceSlot, add(accountBalance, value))
+           sstore(accountBalanceSlot, newBalance)
        }
    }
```
