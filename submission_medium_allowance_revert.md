# `allowance()` Reverts for Zero Addresses Instead of Returning 0, Breaking Integrations

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: `allowance(owner, spender)` should return `0` for any address pair that has no approval set, including when either address is `address(0)`. This is consistent with OpenZeppelin and other implementations.
* **Specific Issue**: `_allowance` reverts when either `owner` or `spender` is `address(0)`. This breaks tooling and integrations that query allowances for edge cases.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _allowance(address owner, address spender) internal view returns (uint256 remaining) {
        assembly {
            if or(iszero(owner), iszero(spender)) {
                revert(0, 0) // @> Reverts instead of returning 0
            }
            // ...
        }
    }
```

## Risk

**Likelihood**:

* **Medium**: Indexers, analytics tools, and some protocols query allowance for address(0) as part of their operations or edge-case handling.

**Impact**:

* **Medium**: Breaks compatibility with tooling; can cause UI errors or failed batch operations in protocols that iterate over allowances.

## Proof of Concept

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
}

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
```

## Recommended Mitigation

```diff
    function _allowance(address owner, address spender) internal view returns (uint256 remaining) {
        assembly {
-           if or(iszero(owner), iszero(spender)) {
-               revert(0, 0)
-           }
+           // Return 0 for zero addresses to match ecosystem expectations
+           if or(iszero(owner), iszero(spender)) {
+               mstore(0x00, 0)
+               return(0x00, 0x20)
+           }
            // ...
        }
    }
```
