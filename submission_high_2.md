# Missing `Approval` event on allowance decrease (`transferFrom`) breaks allowance tracking and security monitoring

**File Scope:** `src/helpers/ERC20Internals.sol`

# Root + Impact

## Description

* **Normal Behavior**: When `transferFrom` spends allowance, many ERC20 implementations (e.g., OpenZeppelin) emit an `Approval` event reflecting the new allowance. Off-chain systems (wallets, explorers, The Graph, monitoring bots) rely on these events to track and alert on allowance changes.
* **Specific Issue**: `Token-0x` reduces allowance inside `_spendAllowance` but does not emit an `Approval` event. As a result, off-chain views of allowances can become stale and security alerts will not fire on allowance reductions.

```solidity
// Root cause in src/helpers/ERC20Internals.sol

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        assembly ("memory-safe") {
            // ... compute allowanceSlot and load currentAllowance
            // ... revert on insufficient allowance
-           sstore(allowanceSlot, sub(currentAllowance, value)) // @> No Approval event emitted for allowance change
+           // Expected: emit Approval(owner, spender, sub(currentAllowance, value))
        }
    }
```

## Risk

**Likelihood**:

* **High**: Allowance usage (`transferFrom`) is common in DeFi and wallets; many protocols rely on off-chain event-based allowance tracking rather than frequent on-chain reads.

**Impact**:

* **High**: Security monitoring fails to detect allowance changes promptly, enabling stealthy drain patterns or misconfigured approvals to go unnoticed. Users and protocols get incorrect UI/integrations for allowances.
* **Operational Risk**: Indexers and analytics relying on events will show stale approvals, affecting audits, dashboards, and automations.

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

contract MissingApprovalOnSpendTest is Test {
    Token token;
    address owner = address(0xA1);
    address spender = address(0xB2);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        token = new Token();
        token.mint(owner, 100);
        vm.prank(owner);
        token.approve(spender, 60);
    }

    function testTransferFromReducesAllowanceButNoApprovalEvent() public {
        // Expect Approval event when allowance changes
        vm.prank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, 30);
        token.transferFrom(owner, address(0xC3), 30); // Fails: no Approval event emitted
    }
}
```

## Recommended Mitigation

Emit an `Approval` event in `_spendAllowance` after updating the allowance.

```diff
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        assembly ("memory-safe") {
            // ... after computing newAllowance
-           sstore(allowanceSlot, sub(currentAllowance, value))
+           let newAllowance := sub(currentAllowance, value)
+           sstore(allowanceSlot, newAllowance)
+           mstore(0x00, newAllowance)
+           // keccak256("Approval(address,address,uint256)")
+           log3(0x00, 0x20, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, owner, spender)
        }
    }
```
