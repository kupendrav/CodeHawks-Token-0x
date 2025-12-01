# Token-0x

- Starts: December 04, 2025 Noon UTC
- Ends: December 11, 2025 Noon UTC

- nSLOC: 222

[//]: # (contest-details-open)

## About the Project

Token-0x, A secure and cheap base ERC20 implementation, which follows the ERC20 standard. Token-0x has implemented all the necessary functions required to be a compliant ERC20 token but in different way. Token-0x achieves the secure and cheap operations by using a combination of Solidity and Yul in the base implementation. User can use it as ERC20 token like openzeppelin implementation.

```
[GitHub](https://github.com/GHexxerBrdv/Token-0x.git)
```

## Actors

1. All the users and DeFi protocols

Example:

```
DeFi protocols can use this token as a base token for their protocol for rewards, native token for their protocol etc.
```

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

```js
src/
├── ERC20.sol
├── IERC20.sol
├── helpers
   ├── IERC20Errors.sol
   └── ERC20Internals.sol

```

## Compatibilities

All EVM compatible chains are suppose to use this token.

```
Compatibilities:
  Blockchains:
      - Ethereum/Any EVM
```

[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

Follow following steps to setup the project

Example:

Build:
```bash

git clone https://github.com/CodeHawks-Contests/2025-12-token-0x.git

forge install

```

Tests:
```bash
Forge test
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues
 NA
 
[//]: # (known-issues-close)