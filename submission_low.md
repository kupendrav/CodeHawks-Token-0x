# `balanceOf(address(0))` reverts, breaking ERC20 ecosystem expectations

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: Many ERC20 integrations (indexers, explorers, tooling) call `balanceOf(address(0))` to check burn/mint accounting or display placeholders. ERC20 implementations typically return `0` for the zero address rather than revert.
* **Specific Issue**: `Token-0x`'s `_balanceOf` reverts when `owner == address(0)`. This diverges from prevailing practice and breaks consumer assumptions, causing unnecessary failures in tooling and protocol integrations that query the zero address.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _balanceOf(address owner) internal view returns (uint256) {
        assembly {
            if iszero(owner) {
                revert(0, 0) // @> Revert on zero address, instead of returning 0
            }
            // ... mapping lookup and return
        }
    }
```

## Risk

**Likelihood**:

* Tooling and indexers frequently query `balanceOf(address(0))` during UI updates and analytics.
* DeFi protocols occasionally perform sanity checks involving the zero address balance.

**Impact**:

* UI/Indexer Errors: Wallets/Explorers (and The Graph subgraphs) can crash or show errors instead of rendering balances.
* Compatibility: Non-standard behavior reduces drop-in compatibility vs. widely used ERC20s (e.g., OpenZeppelin), increasing integration friction.

## Proof of Concept

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
}

contract BalanceOfZeroTest is Test {
    Token token;

    function setUp() public {
        token = new Token();
    }

    function testBalanceOfZeroAddressReverts() public {
        vm.expectRevert();
        token.balanceOf(address(0)); // Reverts due to iszero(owner) guard
    }
}
```

## Recommended Mitigation

```diff
-    function _balanceOf(address owner) internal view returns (uint256) {
-        assembly {
-            if iszero(owner) {
-                revert(0, 0)
-            }
-            // mapping lookup and return
-        }
-    }
+    function _balanceOf(address owner) internal view returns (uint256) {
+        assembly {
+            // Return 0 for zero address to align with ecosystem expectations
+            if iszero(owner) {
+                mstore(0x00, 0)
+                return(0x00, 0x20)
+            }
+            // mapping lookup and return
+        }
+    }
```
