# TetraUSD (tUSD) Stablecoin Infrastructure
### Institutional-Grade Centrally Controlled Stablecoin on BNB Smart Chain
## 📄 Executive Overview
**TetraUSD (tUSD)** is a fiat-pegged stablecoin designed for regulated financial ecosystems. Unlike decentralized protocols (e.g., DAI), tUSD is architected as a **Managed Digital Ledger**. It provides the issuing authority with absolute oversight and intervention capabilities, ensuring that the asset can meet strict Anti-Money Laundering (AML) requirements, facilitate court-ordered asset recovery, and maintain a stable 1:1 USD peg through active treasury management.
### Key Asset Parameters
| Parameter | Value |
|---|---|
| **Name** | Tetra USD |
| **Symbol** | tUSD |
| **Decimals** | 6 (Matches USDT precision) |
| **Blockchain** | BNB Smart Chain (BEP-20) |
| **Collateral Model** | 1:1 USDT Backing & BNB (Oracle-based) |
| **Governance** | Centralized (Owner-Led) |
## 🏗 System Architecture & Design
The TetraUSD smart contract is a monolithic, non-upgradeable infrastructure that prioritizes execution speed, security, and administrative agility. It integrates industry-standard protocols (EIP-712, Chainlink) into a high-control environment.
### 1. Administrative Control Layer
The system utilizes a multi-tier permission model:
 * **Owner:** The ultimate authority. Can bypass standard ERC20 logic to move, burn, or freeze any balance.
 * **Minter:** Authorized to issue new tokens to users based on off-chain or on-chain deposits.
 * **Treasury:** A dedicated off-chain managed address where all collateral (USDT) is redirected.
### 2. The Compliance Hook (_beforeTransfer)
Every transaction (except admin overrides) is passed through a central security filter. This ensures that:
 * Global pauses are respected.
 * Blacklisted/Frozen entities cannot interact with the ledger.
 * Exit liquidity to unauthorized DEX pairs is blocked.
### 3. Gasless Execution (EIP-712)
tUSD supports meta-transactions, allowing users to sign a transfer off-chain. A third-party relayer can then execute this on-chain, paying the gas fee in BNB, thus improving the user experience for non-native users.
## ⚡ Critical Disclosure: Centralization Model
**Transparency is a core requirement for institutional trust.** Auditors and investors must acknowledge that TetraUSD possesses "God Mode" administrative powers:
 * **BuyTransfer (Force Move):** The Owner can transfer any amount of tUSD from any wallet to any destination without a user signature.
 * **burn (Force Destroy):** The Owner can permanently destroy tokens in any user's wallet.
 * **ServerMint (Ledger Sync):** A unique function that credits balances **without updating the totalSupply**. This is used for internal accounting sync but creates a deliberate on-chain accounting discrepancy.
 * **DEX Sell Block:** The contract can programmatically prevent users from selling tUSD on PancakeSwap via the pancakePair restriction.
 * **Asset Sweeping:** All native BNB and ERC20 tokens (USDT) held by the contract can be "swept" to the treasury by the Owner at any time.
## 🛡 Security & Risk Management
### Threat Model & Mitigation
 * **Private Key Risk:** The system is entirely dependent on the Owner key. **Mitigation:** Mandatory use of a Multi-Signature (3-of-5) Hardware Wallet vault for the Owner role.
 * **Oracle Failure:** BNB prices are fetched via Chainlink. **Mitigation:** The Owner can pause the contract immediately if the oracle heartbeat fails or price deviation exceeds safety thresholds.
 * **Liquidity Risk:** Since USDT deposits are redirected to the Treasury, redemptions via the contract depend on the Owner manually funding the contract balance.
## 📂 Repository Structure
```text
tetrausd-stablecoin/
├── contracts/             # Optimized TetraUSD.sol (Solidity 0.8.24)
├── docs/                  # Technical Deep-Dives
│   ├── architecture.md    # Logic flow and component interaction
│   ├── admin-powers.md    # Detailed audit of administrative functions
│   └── buy-sell-flow.md   # Treasury redirection and oracle logic
├── audit/                 # Auditor Resources
│   ├── high-risk-funcs.md # Focus areas for security reviewers
│   └── threat-model.md    # Analysis of potential attack vectors
└── transparency/          # Compliance & Reserves
    ├── reserve-model.md   # Proof of Reserve (PoR) methodology
    └── blacklist-policy.md# Legal framework for account restrictions

```
## 🚀 Deployment & Integration
### Prerequisites
 * Node.js v18+
 * Hardhat or Foundry
 * USDT Address (BSC): 0x55d398326f99059fF775485246999027B3197955
 * Chainlink BNB/USD: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
### Quick Start
```bash
# Install dependencies
npm install

# Compile the contract
npx hardhat compile

# Run security tests
npx hardhat test

```
## ⚖️ Legal & Compliance
The TetraUSD infrastructure is provided "as is". By interacting with this smart contract, participants acknowledge that the asset is centrally managed and subject to the administrative decisions of the Issuer.
**License:** MIT
**Copyright:** (c) 2026 TetraUSD Project. All Rights Reserved.
*For high-priority security inquiries or institutional partnership requests, please contact compliance@tetrausd.io.*
