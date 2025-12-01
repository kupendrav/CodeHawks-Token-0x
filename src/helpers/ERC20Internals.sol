// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ERC20Internals {
    mapping(address account => uint256) internal _balances;
    mapping(address account => mapping(address spender => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;

    function totalSupply_() internal view returns (uint256) {
        assembly {
            let slot := _totalSupply.slot
            let supply := sload(slot)
            mstore(0x00, supply)
            return(0x00, 0x20)
        }
    }

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
            mstore(add(ptr, 0x20), 0)
            return(ptr, 0x20)
        }
    }

    function _approve(address owner, address spender, uint256 value) internal virtual returns (bool success) {
        assembly ("memory-safe") {
            if iszero(owner) {
                mstore(0x00, shl(224, 0xe602df05))
                mstore(add(0x00, 4), owner)
                revert(0x00, 0x24)
            }
            if iszero(spender) {
                mstore(0x00, shl(224, 0x94280d62))
                mstore(add(0x00, 4), spender)
                revert(0x00, 0x24)
            }

            let ptr := mload(0x40)
            let baseSlot := _allowances.slot

            mstore(ptr, owner)
            mstore(add(ptr, 0x20), baseSlot)
            let initialHash := keccak256(ptr, 0x40)
            mstore(ptr, spender)
            mstore(add(ptr, 0x20), initialHash)

            let allowanceSlot := keccak256(ptr, 0x40)
            sstore(allowanceSlot, value)

            success := 1

            mstore(0x00, value)
            log3(0x00, 0x20, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, owner, spender)
        }
    }

    function _allowance(address owner, address spender) internal view returns (uint256 remaining) {
        assembly {
            if or(iszero(owner), iszero(spender)) {
                revert(0, 0)
            }

            let ptr := mload(0x40)
            let baseSlot := _allowances.slot

            mstore(ptr, owner)
            mstore(add(ptr, 0x20), baseSlot)
            let initialHash := keccak256(ptr, 0x40)
            mstore(ptr, spender)
            mstore(add(ptr, 0x20), initialHash)

            let allowanceSlot := keccak256(ptr, 0x40)
            remaining := sload(allowanceSlot)
        }
    }

    function _transfer(address from, address to, uint256 value) internal returns (bool success) {
        assembly ("memory-safe") {
            if iszero(from) {
                mstore(0x00, shl(224, 0x96c6fd1e))
                mstore(add(0x00, 4), 0x00)
                revert(0x00, 0x24)
            }

            if iszero(to) {
                mstore(0x00, shl(224, 0xec442f05))
                mstore(add(0x00, 4), 0x00)
                revert(0x00, 0x24)
            }

            let ptr := mload(0x40)
            let baseSlot := _balances.slot

            mstore(ptr, from)
            mstore(add(ptr, 0x20), baseSlot)
            let fromSlot := keccak256(ptr, 0x40)
            let fromAmount := sload(fromSlot)
            mstore(ptr, to)
            mstore(add(ptr, 0x20), baseSlot)
            let toSlot := keccak256(ptr, 0x40)
            let toAmount := sload(toSlot)

            if lt(fromAmount, value) {
                mstore(0x00, shl(224, 0xe450d38c))
                mstore(add(0x00, 4), from)
                mstore(add(0x00, 0x24), fromAmount)
                mstore(add(0x00, 0x44), value)
                revert(0x00, 0x64)
            }

            sstore(fromSlot, sub(fromAmount, value))
            sstore(toSlot, add(toAmount, value))
            success := 1
            mstore(ptr, value)
            log3(ptr, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to)
        }
    }

    function _mint(address account, uint256 value) internal {
        assembly ("memory-safe") {
            if iszero(account) {
                mstore(0x00, shl(224, 0xec442f05))
                mstore(add(0x00, 4), 0x00)
                revert(0x00, 0x24)
            }

            let ptr := mload(0x40)
            let balanceSlot := _balances.slot
            let supplySlot := _totalSupply.slot

            let supply := sload(supplySlot)
            sstore(supplySlot, add(supply, value))

            mstore(ptr, account)
            mstore(add(ptr, 0x20), balanceSlot)

            let accountBalanceSlot := keccak256(ptr, 0x40)
            let accountBalance := sload(accountBalanceSlot)
            sstore(accountBalanceSlot, add(accountBalance, value))
        }
    }

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
            sstore(supplySlot, sub(supply, value))

            mstore(ptr, account)
            mstore(add(ptr, 0x20), balanceSlot)

            let accountBalanceSlot := keccak256(ptr, 0x40)
            let accountBalance := sload(accountBalanceSlot)
            sstore(accountBalanceSlot, sub(accountBalance, value))
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            let baseSlot := _allowances.slot
            mstore(ptr, owner)
            mstore(add(ptr, 0x20), baseSlot)
            let initialHash := keccak256(ptr, 0x40)
            mstore(ptr, spender)
            mstore(add(ptr, 0x20), initialHash)
            let allowanceSlot := keccak256(ptr, 0x40)
            let currentAllowance := sload(allowanceSlot)

            if lt(currentAllowance, value) {
                mstore(0x00, shl(224, 0xfb8f41b2))
                mstore(add(0x00, 4), spender)
                mstore(add(0x00, 0x24), currentAllowance)
                mstore(add(0x00, 0x44), value)
                revert(0, 0x64)
            }
            sstore(allowanceSlot, sub(currentAllowance, value))
        }
    }
}
