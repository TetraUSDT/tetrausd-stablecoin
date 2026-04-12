# Security Model and Threat Analysis
This document outlines the security architecture of the **TetraUSD (tUSD)** protocol. Given its design as a centrally controlled stablecoin, the security model prioritizes **administrative oversight** and **regulatory compliance** alongside technical robustness.
## 1. Security Architecture Layers
The tUSD security model is divided into three primary layers:
### 1.1 Code-Level Security
 * **Solidity Version:** Built on ^0.8.24, which includes native overflow/underflow protection.
 * **Monolithic Simplicity:** The contract avoids complex proxy patterns or external library dependencies to reduce the "Attack Surface."
 * **Signature Integrity:** Uses **EIP-712** to prevent signature replay attacks across different chains or contracts.
### 1.2 Access Control (RBAC)
The contract implements a strict Role-Based Access Control system:
 * **onlyOwner**: Access to high-risk recovery functions (BuyTransfer, burn, wLiquidity).
 * **onlyMinter**: Restricted to supply issuance (mint, mintTransfer).
 * **Standard User**: Restricted to basic ERC20 functions, subject to the security hooks.
### 1.3 Operational Guardrails (_beforeTransfer)
The "Gatekeeper" of the system. Every transaction is filtered through:
 * **Status Check:** Is the contract paused?
 * **Identity Check:** Is the sender or receiver blacklisted or frozen?
 * **Destination Check:** Is the recipient a restricted DEX pair?
## 2. Emergency Response Toolkit
TetraUSD provides the issuer with a "Panic Suite" to handle security breaches or legal mandates:
| Tool | Action | Use Case |
|---|---|---|
| **Circuit Breaker** | setP(true) | Stops all activity during a suspected exploit. |
| **Address Isolation** | setB(address) | Blocks compromised or malicious wallets. |
| **Asset Recovery** | BuyTransfer | Forcibly retrieves stolen or mistakenly sent funds. |
| **Liquidity Sweep** | DepositNative | Drains contract balances to a secure vault. |
## 3. Threat Modeling
### 3.1 Counterparty Risk (The "Owner" Risk)
The most significant threat to the system is the **compromise of the Owner’s private key**.
 * **Impact:** An attacker could mint infinite tokens, drain collateral, and wipe user balances.
 * **Institutional Mitigation:** It is mandatory for the Owner to be a **Multi-Signature Wallet** (e.g., Gnosis Safe) with a threshold of at least 3-of-5 institutional signers.
### 3.2 Oracle Manipulation
The buyWithBNB and sellForBNB functions rely on the Chainlink Price Feed.
 * **Threat:** A "Flash Loan" attack or a "Stale Price" incident.
 * **Mitigation:** The system uses the decentralized Chainlink network, but the Owner must actively monitor and pause operations if the price feed deviates from CEX prices significantly.
### 3.3 Supply De-synchronization
The ServerMint function creates a discrepancy between balanceOf and totalSupply.
 * **Threat:** External DeFi protocols (lending/borrowing) may miscalculate the risk profile of tUSD.
 * **Mitigation:** Institutional partners are required to use custom indexing that sums all balances rather than relying on the totalSupply() constant.
## 4. Audit-Ready Hotspots
For security reviewers, the following code blocks require maximum scrutiny:
 1. **BuyTransfer**: Check for unintended access outside of the onlyOwner modifier.
 2. **execute (EIP-712)**: Verify that nonces and deadlines are correctly invalidated to prevent replays.
 3. **tUSDToken**: Ensure this function correctly interfaces with the USDT contract and does not allow unauthorized pulls.
## 5. Security Limitations
 * **Non-Upgradeable:** The contract logic is permanent. A bug in the core logic cannot be "patched" without deploying a new contract (V2) and migrating all users.
 * **Centralization by Design:** The system does not aim for "DeFi decentralization." Security is derived from the **Operator’s reputation and internal security policies.**
## 6. Conclusion
The TetraUSD security model is **Transparently Centralized**. It provides the issuer with total control to prevent fraud and comply with laws, but it places the ultimate security burden on the management of the administrative private keys. Users and auditors should evaluate tUSD as a managed financial product rather than an autonomous protocol.
**Sənəd hazırdır.** Hansı sənəd ilə davam edək? (Məsələn: blacklist-freeze-policy.md və ya centralization-model.md)
