# TetraUSD — System Architecture

## 1. Introduction

TetraUSD (tUSD) is a controlled stablecoin infrastructure designed with a hybrid architecture combining ERC20 token standards, administrative control layers, oracle-based pricing, and treasury-managed liquidity mechanisms.

The system is intentionally structured to support:

- controlled token issuance and redemption
- administrative intervention capabilities
- flexible liquidity integration
- security-focused transaction validation
- audit-ready modular design

---

## 2. Architectural Overview

TetraUSD architecture consists of the following primary layers:

1. Token Layer  
2. Control Layer  
3. Issuance & Redemption Layer  
4. Oracle Layer  
5. Treasury Layer  
6. Execution Layer (EIP-712)  
7. Administrative Layer  
8. Asset Management Layer  

Each layer is interconnected and contributes to the system’s overall functionality and control.

---

## 3. Token Layer

The Token Layer implements core ERC20-compatible functionality, including:

- `balanceOf` tracking
- `allowance` management
- `transfer`
- `transferFrom`
- `approve`
- batch transfers (`Transfers`)

### Characteristics

- 6 decimal precision
- standard Transfer and Approval events
- supports wallet and exchange compatibility

This layer ensures interoperability with existing blockchain infrastructure.

---

## 4. Control Layer

The Control Layer enforces security restrictions through the internal `_beforeTransfer` hook.

### Enforced Rules

- Global pause (`paused`)
- Blacklist restriction (`blacklisted`)
- Freeze restriction (`frozen`)
- DEX sell blocking (`pancakePair`)

### DEX Sell Restriction

If a transfer is directed to a defined DEX pair address:

if(to == pancakePair){
revert(“DEX SELL BLOCKED”);
}

This prevents token selling through decentralized exchanges.

### Purpose

- prevent unauthorized movement
- enforce compliance restrictions
- protect liquidity and system stability

---

## 5. Issuance & Redemption Layer

This layer governs how tokens enter and exit circulation.

### Minting Mechanisms

1. **Direct Minting**
   - Authorized minters can mint tokens
   - Owner can act as fallback minter

2. **USDT-Based Minting**
   - Function: `buyWithUSDT`
   - 1:1 mint ratio (USDT → tUSD)
   - Funds sent to treasury

3. **BNB-Based Minting**
   - Function: `buyWithBNB`
   - Uses Chainlink oracle pricing

---

### Burning Mechanisms

1. **Owner Burn**
   - Direct burn from any wallet

2. **USDT Redemption**
   - Function: `sellForUSDT`
   - Token is burned
   - USDT returned to user

3. **BNB Redemption**
   - Function: `sellForBNB`
   - Token is burned
   - BNB returned via contract liquidity

---

### Observations

- Supply is dynamic
- Owner retains full control over burn logic
- Liquidity availability affects redemption reliability

---

## 6. Oracle Layer

The system integrates Chainlink price feeds via:

AggregatorV3Interface

### Usage

- determines BNB price
- used in:
  - `buyWithBNB`
  - `sellForBNB`

### Precision

- price feed returns 8 decimal values

### Risks

- oracle downtime
- stale price data
- dependency on external infrastructure

---

## 7. Treasury Layer

The treasury address plays a critical role in fund management.

### Responsibilities

- receives USDT from purchases
- stores backing assets
- serves as off-chain reserve endpoint

### Characteristics

- externally controlled address
- not enforced on-chain auditing
- relies on off-chain trust model

---

## 8. Execution Layer (EIP-712)

TetraUSD includes a signature-based execution system.

### Features

- off-chain message signing
- on-chain verification
- nonce tracking
- deadline enforcement

### Function

execute(…)

### Benefits

- gasless transaction capability
- delegated execution
- replay attack protection

---

## 9. Administrative Layer

The Administrative Layer introduces centralized control.

### Roles

- Owner
- Minter
- Minter Admin

### Capabilities

- mint tokens
- burn tokens
- transfer user balances
- pause system
- blacklist / freeze users
- configure DEX pair

---

## 10. Asset Management Layer

This layer controls contract-held assets.

### Functions

#### Liquidity Withdrawal

wLiquidity(…)

- withdraw LP tokens
- move liquidity to owner

#### Token Sweep

DepositToken(…)
DepositTokens(…)

- transfer all ERC20 tokens from contract

#### Native Sweep

DepositNative(…)

- withdraw all BNB from contract

---

## 11. External Interaction Layer

TetraUSD interacts with:

- USDT contract (ERC20)
- Chainlink Oracle
- LP token contracts
- external ERC20 tokens

### Special Function

- withdraw all BNB from contract

---

## 11. External Interaction Layer

TetraUSD interacts with:

- USDT contract (ERC20)
- Chainlink Oracle
- LP token contracts
- external ERC20 tokens

### Special Function

tUSDToken(…)

Allows pulling tokens from user wallets (if approved).

---

## 12. Security Architecture

Security is enforced via:

- transfer validation hook
- role-based access control
- signature validation (EIP-712)
- pause mechanism
- blacklist / freeze

### Limitations

- owner has unrestricted authority
- no on-chain governance
- no multi-signature enforcement (current version)

---

## 13. Centralization Model

TetraUSD is not decentralized.

### System Characteristics

- owner-controlled minting
- owner-controlled burning
- user balance modification possible
- liquidity withdrawal possible
- transfers can be restricted

### Classification

**Centrally Controlled Stablecoin Infrastructure**

---

## 14. Risk Considerations

### Smart Contract Risk
- complex control logic
- privileged functions

### Liquidity Risk
- dependent on treasury and contract balance

### Oracle Risk
- external dependency

### Governance Risk
- single owner authority

---

## 15. Architectural Summary

TetraUSD architecture combines:

- ERC20 token logic
- centralized control mechanisms
- oracle-based pricing
- treasury-backed operations
- advanced administrative capabilities

This structure enables:

- flexible monetary control
- intervention capability
- hybrid CeFi/DeFi functionality

---

## 16. Final Note

TetraUSD is designed as a **controlled financial infrastructure layer**, not as a permissionless decentralized system.

All integrations, users, and stakeholders must fully understand:

- administrative control scope
- liquidity dependency
- oracle reliance
- operational authority structure
