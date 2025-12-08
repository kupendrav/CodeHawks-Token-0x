# Infinite Allowance (`type(uint256).max`) Gets Depleted Instead of Staying Infinite

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: Per ERC20 convention (OpenZeppelin, Solmate), setting allowance to `type(uint256).max` represents "infinite" approval that should NOT be decremented on `transferFrom`. This is a gas optimization and UX pattern widely adopted.
* **Specific Issue**: `_spendAllowance` always subtracts `value` from `currentAllowance` without checking if allowance is `type(uint256).max`. This breaks the infinite allowance pattern.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        assembly ("memory-safe") {
            // ...
            let currentAllowance := sload(allowanceSlot)

            if lt(currentAllowance, value) {
                revert(...)
            }
            sstore(allowanceSlot, sub(currentAllowance, value)) // @> Always subtracts, even for max allowance
        }
    }
```

## Risk

**Likelihood**:

* **High**: Infinite approvals are standard practice for DEXs (Uniswap), lending protocols (Aave), and aggregators. Users routinely approve `type(uint256).max`.

**Impact**:

* **High**: Users who set infinite approval will have their allowance depleted over time, causing unexpected reverts. This breaks integrations with major DeFi protocols.
* **UX Degradation**: Users must re-approve frequently, wasting gas and causing failed transactions.

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
        // Should stay type(uint256).max, but gets reduced
        assertEq(allowanceAfter, type(uint256).max - 100);
    }
}
```

## Recommended Mitigation

```diff
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        assembly ("memory-safe") {
            // ...
            let currentAllowance := sload(allowanceSlot)

+           // Skip deduction for infinite allowance
+           if eq(currentAllowance, not(0)) { leave }

            if lt(currentAllowance, value) {
                revert(...)
            }
            sstore(allowanceSlot, sub(currentAllowance, value))
        }
    }
```
