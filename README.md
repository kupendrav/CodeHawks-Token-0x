<div align="center">

# 🦅 CodeHawks Security Audit

<img src="https://res.cloudinary.com/droqoz7lg/image/upload/v1689080263/snhkgvtsidryjdtx0pce.png" width="200" alt="CodeHawks Logo"/>

### Token-0x Security Audit Contest

</div>
<img width="1873" height="921" alt="{2D2B3EBD-9815-4E39-B39A-9119960DECA5}" src="https://github.com/user-attachments/assets/b773f915-46c6-4f82-a255-65b5f880356f" />

---

# Token-0x

A secure and cost-efficient base ERC20 implementation that follows the ERC20 standard, built with a combination of Solidity and Yul for optimized gas consumption.

---

## 📋 Table of Contents

- [About](#about)
- [Vulnerability Submissions](#vulnerability-submissions)
- [Contest Details](#contest-details)
- [Features](#features)
- [Actors](#actors)
- [Project Structure](#project-structure)
- [Compatibility](#compatibility)
- [Getting Started](#getting-started)
- [Known Issues](#known-issues)

---

[//]: # (contest-details-open)

## Contest Details

- **Starts:** December 04, 2025 Noon UTC
- **Ends:** December 11, 2025 Noon UTC
- **nSLOC:** 222

[//]: # (contest-details-close)

---

## About

Token-0x is a secure and cheap base ERC20 implementation that fully complies with the ERC20 standard. Unlike traditional implementations, Token-0x achieves secure and cost-effective operations through an innovative combination of Solidity and Yul in its base implementation.

Users can utilize Token-0x as a drop-in replacement for other ERC20 implementations like OpenZeppelin, while benefiting from reduced gas costs.

**Repository:** [GitHub](https://github.com/GHexxerBrdv/Token-0x.git)

---

## 🔍 Vulnerability Submissions

This repository contains detailed security vulnerability reports discovered during the CodeHawks audit contest. The findings are organized by severity level:

### 🔴 Critical Vulnerabilities
- [**Self-Transfer Balance Inflation**](submission_critical_selftransfer.md) - Self-transfers inflate user balance due to stale storage reads

### 🟠 High Severity Vulnerabilities
- [**Unsafe Assembly Integer Overflow/Underflow**](submission_high.md) - Missing overflow/underflow checks in `_burn`, `_mint`, and `_transfer`
- [**Integer Overflow in _transfer**](submission_high_2.md) - Additional overflow vulnerabilities in transfer operations
- [**Infinite Allowance Vulnerability**](submission_high_infinite_allowance.md) - Allowance manipulation leading to unauthorized transfers
- [**Recipient Balance Overflow**](submission_high_recipient_overflow.md) - Overflow in recipient balance during transfers

### 🟡 Medium Severity Vulnerabilities
- [**General Medium Severity Issue**](submission_medium.md) - Medium-level security concerns
- [**Allowance Revert Issue**](submission_medium_allowance_revert.md) - Improper handling of allowance edge cases

### 🟢 Low Severity Vulnerabilities
- [**General Low Severity Issue**](submission_low.md) - Minor security concerns
- [**Memory Write Issue**](submission_low_memory_write.md) - Memory handling inefficiencies

### ⚠️ Major Issues
- [**Major Security Issue**](submission_major.md) - Significant architectural concerns

> **Note**: These vulnerabilities were discovered as part of the CodeHawks security audit contest. Each report includes detailed descriptions, proof of concepts, and recommended mitigations.

---

## Features

- ✅ Full ERC20 standard compliance
- ⚡ Optimized gas consumption using Yul
- 🔒 Secure implementation
- 🔄 Compatible with existing DeFi protocols
- 📦 Easy integration and deployment

---

## Actors

The primary actors in the Token-0x ecosystem include:

1. **Users** - Individual token holders and traders
2. **DeFi Protocols** - Decentralized applications integrating the token

**Use Cases:**
- Base token for protocol rewards
- Native token for DeFi protocols
- General-purpose ERC20 token implementation

---

[//]: # (scope-open)

## Project Structure

```
├── src
│   ├── ERC20.sol              # Main ERC20 implementation
│   ├── IERC20.sol             # ERC20 interface
│   └── helpers
│       ├── IERC20Errors.sol   # Error definitions
│       └── ERC20Internals.sol # Internal functions and Yul optimizations
```

[//]: # (scope-close)

---

## Compatibility

Token-0x is designed to work on all EVM-compatible blockchains, including:

- Ethereum
- Polygon
- Binance Smart Chain
- Avalanche
- Arbitrum
- Optimism
- Any other EVM-compatible chain

---

[//]: # (getting-started-open)

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed on your system

### Installation

1. Clone the repository:
```bash
git clone https://github.com/CodeHawks-Contests/2025-12-token-0x.git
cd 2025-12-token-0x
```

2. Install dependencies:
```bash
forge install
```

### Building

To compile the contracts:
```bash
forge build
```

### Testing

To run the test suite:
```bash
forge test
```

For verbose output:
```bash
forge test -vvv
```

[//]: # (getting-started-close)

---

[//]: # (known-issues-open)

## Known Issues

No known issues at this time.

[//]: # (known-issues-close)

---

## License

This project is part of the CodeHawks audit contest.

