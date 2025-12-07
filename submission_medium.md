# `_mint` and `_burn` functions do not emit `Transfer` events, violating ERC20 standard

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

*   **Normal Behavior**: The ERC20 standard (EIP-20) mandates that a `Transfer` event MUST be triggered when tokens are transferred, including when tokens are created (`mint`) or destroyed (`burn`). For minting, the `_from` address is `0x0`. For burning, the `_to` address is `0x0`.
*   **Specific Issue**: The `_mint` and `_burn` functions in `ERC20Internals.sol` update the state (balances and total supply) but fail to emit the required `Transfer` event.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _mint(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ... (state updates)
            // @> Missing log3 for Transfer event
        }
    }

    function _burn(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ... (state updates)
            // @> Missing log3 for Transfer event
        }
    }
```

## Risk

**Likelihood**:

*   **Medium**: The contract is a base implementation meant to be inherited. Any project using this base and exposing mint/burn functionality will inherit this non-compliance.

**Impact**:

*   **Medium**:
    *   **Broken Integrations**: Off-chain indexers (like Etherscan, The Graph) and wallets rely on `Transfer` events to track token balances and activity. Minted or burned tokens will not be reflected in these services, leading to incorrect balance displays and history.
    *   **Standard Violation**: While EIP-20 technically uses "SHOULD" for minting events, it is a de-facto requirement for any functional token. Omitting it renders the token unusable in the broader ecosystem.

## Proof of Concept

**Short Explanation**: 
We verify the issue by calling `mint` and expecting a `Transfer` event using Foundry's `vm.expectEmit`. The test fails because the `_mint` function updates the state (balances) but does not execute the `log3` opcode to emit the event. The same applies to `_burn`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
    function mint(address to, uint256 amount) public { _mint(to, amount); }
    function burn(address from, uint256 amount) public { _burn(from, amount); }
}

contract MissingEventsTest is Test {
    Token token;
    address user = address(0x1);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public { token = new Token(); }

    function testMintEmitsTransfer() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, 100);
        token.mint(user, 100); // Fails to emit event
    }
}
```

## Recommended Mitigation

Add the missing event logs in the assembly blocks.

```diff
    function _mint(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ... existing code ...
            sstore(accountBalanceSlot, add(accountBalance, value))

+           mstore(ptr, value)
+           log3(ptr, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0, account)
        }
    }

    function _burn(address account, uint256 value) internal {
        assembly ("memory-safe") {
            // ... existing code ...
            sstore(accountBalanceSlot, sub(accountBalance, value))

+           mstore(ptr, value)
+           log3(ptr, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, account, 0)
        }
    }
```
