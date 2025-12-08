# `_balanceOf` Writes Zero to Adjacent Memory, Potential Memory Corruption in Complex Calls

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: View functions should not modify memory in ways that could affect caller state. They should only read and return data cleanly.
* **Specific Issue**: `_balanceOf` writes `0` to `ptr + 0x20` after loading the balance. This clears 32 bytes of memory that could be in use by the calling context in complex call chains or composable contracts.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _balanceOf(address owner) internal view returns (uint256) {
        assembly {
            // ...
            let amount := sload(dataSlot)
            mstore(ptr, amount)
            mstore(add(ptr, 0x20), 0)  // @> Writes 0 to memory after the return value
            return(ptr, 0x20)
        }
    }
```

## Risk

**Likelihood**:

* **Low-Medium**: Requires specific call patterns where memory at `ptr + 0x20` is being used by calling code. More likely in complex composable DeFi or when called via delegatecall.

**Impact**:

* **Medium**: Memory corruption can lead to unpredictable behavior, incorrect calculations, or security vulnerabilities in composing contracts.
* **Silent Bugs**: Hard to debug since the corruption is subtle and may only manifest under specific conditions.

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

contract MemoryCorruptionTest is Test {
    Token token;
    address user = address(0x123);

    function setUp() public {
        token = new Token();
        token.mint(user, 500);
    }

    function testBalanceOfMemoryWrite() public view {
        // This test shows the function works, but the memory write is unnecessary
        // and could corrupt memory in more complex scenarios
        uint256 bal = token.balanceOf(user);
        assertEq(bal, 500);
    }
}
```

## Recommended Mitigation

Remove the unnecessary memory write:

```diff
    function _balanceOf(address owner) internal view returns (uint256) {
        assembly {
            if iszero(owner) {
                revert(0, 0)
            }

            let baseSlot := _balances.slot
            let ptr := mload(0x40)
            mstore(ptr, owner)
            mstore(add(ptr, 0x20), baseSlot)
            let dataSlot := keccak256(ptr, 0x40)
            let amount := sload(dataSlot)
            mstore(ptr, amount)
-           mstore(add(ptr, 0x20), 0)
            return(ptr, 0x20)
        }
    }
```
