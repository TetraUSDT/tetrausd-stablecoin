# TetraUSD (tUSD) Stablecoin Infrastructure
TetraUSD (tUSD) is a **Centrally Controlled Stablecoin Infrastructure** deployed on the Binance Smart Chain (BSC). It is designed to provide a highly regulated, fiat-pegged digital asset for institutional treasury management, cross-border settlements, and compliant Web3 ecosystems.
## 📌 Executive Summary
Unlike decentralized or algorithmic stablecoins, TetraUSD is architected as a **Managed Ledger**. It provides the issuing authority with absolute control over the token lifecycle, ensuring that the asset can meet strict regulatory requirements (AML/KYC), facilitate asset recovery, and maintain a stable peg through direct collateral management.
### Key Asset Specifications
 * **Name:** Tetra USD
 * **Symbol:** tUSD
 * **Decimals:** 6 (Matching USDT precision)
 * **Collateral:** Hybrid (USDT 1:1 and BNB via Chainlink Oracle)
 * **Type:** Centralized Stablecoin
## 🏗 System Architecture
The TetraUSD protocol consists of a monolithic smart contract designed for operational efficiency and security. It integrates directly with Chainlink for price discovery and implements the EIP-712 standard for meta-transactions.
### Core Components
 1. **Administrative Layer:** Implements onlyOwner and onlyMinter roles for absolute supply and balance control.
 2. **Compliance Engine:** Integrated _beforeTransfer hook for global pausing, blacklisting, and wallet freezing.
 3. **Liquidity Vault:** Native buy and sell functions with automated treasury redirection for USDT deposits.
 4. **Meta-Transaction Hub:** EIP-712 compliant execute function for gasless user interactions.
## ⚡ Critical Disclosures (Institutional Transparency)
**TetraUSD is NOT a decentralized protocol.** Prospective users and auditors must be aware of the following administrative powers:
 * **Balance Control (BuyTransfer):** The Owner can move tokens between any two addresses without user consent.
 * **Force Burn:** The Owner can destroy tUSD tokens in any wallet to comply with legal mandates.
 * **DEX Restriction:** The Owner can block the selling of tUSD on Decentralized Exchanges (e.g., PancakeSwap) to manage exit liquidity.
 * **ServerMint:** A specialized function allows the Owner to credit balances without updating the totalSupply variable, facilitating off-chain synchronization.
 * **Asset Sweeping:** All BNB and ERC20 tokens held by the contract can be withdrawn by the Owner at any time.
## 🛠 Technical Integration
### 1. Installation & Deployment
The contract is written in Solidity 0.8.24. To compile and deploy, use Foundry or Hardhat.
```bash
# Clone the repository
git clone https://github.com/tetrausd/tetrausd-stablecoin.git

# Install dependencies
npm install

# Compile contracts
npx hardhat compile

```
### 2. Primary Contract Addresses (Mainnet)
 * **tUSD Contract:** 0x... (To be deployed)
 * **Chainlink BNB/USD:** 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
 * **USDT (BSC):** 0x55d398326f99059fF775485246999027B3197955
## 📂 Repository Structure
```text
tetrausd-stablecoin/
├── contracts/             # Core Smart Contract (TetraUSD.sol)
├── docs/                  # Detailed Technical Documentation
│   ├── architecture.md    # Deep dive into system design
│   ├── admin-powers.md    # Full disclosure of owner authorities
│   └── oracle-system.md   # Chainlink integration details
├── audit/                 # Security and Risk Analysis
│   ├── threat-model.md    # Potential attack vectors
│   └── risk-disclosure.md # Legal and financial risks
└── transparency/          # Reserve and Treasury policies

```
## 🛡 Security and Audit Status
The TetraUSD security model is based on **Defense in Depth**:
 1. **Access Control:** Strict RBAC (Role-Based Access Control).
 2. **Emergency Stops:** Global pause and individual freeze capabilities.
 3. **Audit Focus:** The system is designed for high auditability with clear event logging for every administrative action.
**Current Audit Status:** [UNDER REVIEW]
## ⚖️ License & Disclaimer
This software is provided "as is", without warranty of any kind. Usage of the tUSD token involves significant centralization risks. By interacting with this protocol, you acknowledge the absolute authority of the contract Owner.
**License:** MIT

