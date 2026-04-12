# Known Limitations: TetraUSD (tUSD)
This document outlines the intentional technical limitations and design trade-offs of the **TetraUSD (tUSD)** smart contract. These constraints are documented to assist auditors, developers, and institutional partners in understanding the boundaries of the protocol's functionality.
## 1. Technical & Accounting Limitations
### 1.1 Ledger Inconsistency (Total Supply Deviation)
The ServerMint function allows the Owner to credit a user's balance without incrementing the totalSupply variable.
 * **Limitation:** The standard ERC20 invariant sum(balances) == totalSupply is intentionally broken.
 * **Impact:** External DeFi dashboards, block explorers (e.g., BscScan), and analytical tools will display an inaccurate circulating supply.
 * **Requirement:** Integrators must use custom indexing to sum all balances for an accurate debt representation.
### 1.2 Fixed Oracle Precision
The contract uses a hardcoded Chainlink BNB/USD aggregator address and expects 8-decimal precision.
 * **Limitation:** If the price feed address changes or Chainlink updates the decimal precision of this specific pair, the contract cannot be updated (non-upgradeable).
 * **Impact:** A contract migration (v2) would be required if the external oracle infrastructure changes significantly.
## 2. Governance & Control Limitations
### 2.1 Lack of On-Chain Timelocks
All administrative functions (BuyTransfer, burn, setP, etc.) are executed immediately upon transaction confirmation.
 * **Limitation:** There is no "grace period" or "challenge period" between an administrative command and its execution.
 * **Impact:** Users cannot "exit" the protocol after an admin decision is broadcast but before it is finalized.
### 2.2 Non-Upgradeable Architecture
The contract does not utilize a Proxy pattern (e.g., UUPS or Transparent Proxy).
 * **Limitation:** Bugs in the core logic, or the need for new features, cannot be patched.
 * **Impact:** Security vulnerabilities discovered after deployment require a full asset migration to a new contract address.
## 3. Liquidity & Redemption Constraints
### 3.1 Manual Liquidity Provisioning
Because buyWithUSDT redirects collateral to an external treasury, the contract does not hold native liquidity for redemptions by default.
 * **Limitation:** The sellForUSDT function will fail if the Owner has not manually pre-funded the contract.
 * **Impact:** "Instant" on-chain redemption is subject to the Issuer's operational liquidity management.
### 3.2 DEX Dependency (Sell-Block)
The pancakePair restriction is a binary state (Blocked/Unblocked).
 * **Limitation:** The contract cannot distinguish between a retail user selling small amounts and a large whale "dumping" tokens.
 * **Impact:** All users are subject to the same secondary market restrictions once the pancakePair is set.
## 4. ERC20 Compatibility Issues
### 4.1 "Satoshi Setting" Interference
The _beforeTransfer hook applies to the execute (EIP-712) and transferFrom functions.
 * **Limitation:** Standard DeFi "zap" contracts or automated vaults may fail if they attempt to move tUSD while the contract is paused or if the vault address is flagged.
 * **Impact:** Reduced composability with permissionless DeFi protocols.
### 4.2 Fee-on-Transfer (Potential)
The current implementation has a 0% fee.
 * **Limitation:** There is no built-in mechanism to enable dynamic transfer fees without redeploying the contract.
 * **Impact:** Revenue models are limited to the spread between mint/burn or off-chain management fees.
## 5. Security & Trust Assumptions
 * **Operator Integrity:** The system provides NO technical protection against a "Malicious Owner." The security model is purely operational and legal.
 * **Oracle Heartbeat:** The contract does not check the updatedAt timestamp of the Chainlink response. It assumes the latest round data is sufficiently fresh.
## 6. Conclusion
These limitations are **by design** to facilitate a high-control, institutional-grade stablecoin. While they deviate from "DeFi" norms of decentralization and permissionless-ness, they provide the necessary framework for a regulated digital asset.
