# TetraUSD — System Overview

## Introduction

TetraUSD (tUSD) is a controlled stablecoin system designed to provide a programmable, administratively managed, and security-focused digital asset infrastructure.

Unlike fully decentralized stablecoins, TetraUSD is intentionally structured with administrative authority layers to enable controlled issuance, transfer restrictions, and liquidity management.

---

## Core Objective

The primary objective of TetraUSD is to:

- maintain a stable unit representation aligned with USD
- provide controlled minting and burning mechanisms
- integrate both on-chain and off-chain liquidity models
- enable secure, auditable transaction flows
- support regulatory-aligned architecture if required

---

## System Design Philosophy

TetraUSD is built on three core principles:

### 1. Controlled Stability
Stability is enforced through:
- USDT-backed minting (1:1)
- Oracle-based pricing for BNB interactions
- Administrative intervention capabilities

### 2. Security-First Architecture
The system includes:
- blacklist and freeze mechanisms
- global pause functionality
- signature-based transaction execution (EIP-712)
- controlled transfer validation

### 3. Administrative Governance
The system is not permissionless. It includes:
- owner-level authority
- minter role management
- treasury routing control
- liquidity extraction capability

---

## Token Characteristics

| Property | Value |
|--------|------|
| Name | Tetra USD |
| Symbol | tUSD |
| Decimals | 6 |
| Standard | ERC20-compatible |

---

## Core Functional Components

### Minting System
- authorized minters can create tokens
- USDT deposits trigger 1:1 minting
- BNB deposits use oracle pricing

### Burning System
- tokens can be burned via:
  - owner-controlled burn
  - user redemption (USDT / BNB)

### Transfer System
- standard ERC20 transfers
- batch transfers
- signature-based transfers (gasless model)

### Control Layer
- blacklist
- freeze
- pause
- DEX sell restriction

---

## Liquidity Model

TetraUSD integrates:

- USDT liquidity (treasury-based)
- BNB liquidity (contract-based)
- LP token control via admin

---

## System Limitations

- fully centralized administrative control exists
- liquidity depends on treasury and contract balances
- oracle dependency introduces external risk

---

## Conclusion

TetraUSD is not designed as a purely decentralized stablecoin.

It is a controlled, policy-driven stablecoin infrastructure, suitable for environments where governance, intervention, and operational control are required.
