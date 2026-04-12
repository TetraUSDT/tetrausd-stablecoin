# Threat Model: TetraUSD (tUSD) Stablecoin
This document outlines the threat landscape for the **TetraUSD (tUSD)** protocol. It identifies potential adversaries, attack vectors, and the corresponding security controls implemented to protect the integrity of the ledger and the value of the peg.
## 1. Adversary Profiles
| Adversary | Motivation | Capability |
|---|---|---|
| **External Attacker** | Theft of collateral (USDT/BNB) or minting unauthorized tUSD. | High (Smart contract exploits, flash loans, phishing). |
| **Compromised Admin** | Full system takeover via stolen private keys. | **Critical** (Access to all onlyOwner functions). |
| **Malicious User** | Bypassing blacklists or DEX sell restrictions. | Medium (Interaction with DEXs, signature manipulation). |
| **Oracle Manipulator** | Arbitrage via price feed distortion. | High (Market manipulation of BNB/USD pair). |
## 2. Attack Surface Analysis
### 2.1 Smart Contract Entry Points
 * **Public Functions:** buyWithUSDT, buyWithBNB, sellForUSDT, sellForBNB, execute.
 * **Admin Functions:** mint, burn, BuyTransfer, ServerMint, setP, setB, setF.
### 2.2 External Dependencies
 * **Chainlink Oracle:** Dependency on the BNB/USD price feed.
 * **BEP-20 USDT:** Dependency on the stability and availability of the USDT contract.
 * **PancakeSwap:** Secondary market liquidity pools.
## 3. High-Priority Threat Scenarios
### T1: Administrative Key Compromise (The "God Mode" Risk)
 * **Threat:** An attacker gains access to the owner private key.
 * **Impact:** Infinite minting via ServerMint, draining all collateral via DepositNative/Token, and wiping user balances via burn.
 * **Mitigation:**
   * **Mandatory Multisig:** The owner must be a 3-of-5 Gnosis Safe.
   * **Cold Storage:** Signer keys must be held in Hardware Security Modules (HSMs).
   * **Offline Coordination:** High-value admin actions require off-chain multi-step verification.
### T2: Oracle Price Manipulation & Stale Data
 * **Threat:** The BNB/USD price feed is manipulated or stops updating.
 * **Impact:** Users mint tUSD at a discount or redeem for BNB at an inflated rate, draining the contract's native balance.
 * **Mitigation:**
   * **Decentralized Oracles:** Usage of Chainlink's multi-source aggregator.
   * **Circuit Breaker:** The owner can pause the contract immediately if the oracle deviates from CEX prices.
   * **Manual Rebalancing:** Converting excess BNB to USDT to reduce volatility exposure.
### T3: Signature Malleability & Replay Attacks
 * **Threat:** An attacker reuses a user's EIP-712 signature to execute multiple transfers.
 * **Impact:** Unauthorized depletion of a user's balance.
 * **Mitigation:**
   * **Nonces:** Each execute call requires and increments a unique per-user nonce.
   * **Domain Separator:** Signatures are bound to the specific chainId and verifyingContract address.
   * **Deadlines:** Signatures expire after a specified block timestamp.
### T4: Exit Liquidity Lockout (Centralized "Rug-Pull" Vector)
 * **Threat:** The admin sets the pancakePair and stops funding the sell functions.
 * **Impact:** Users are unable to exit their positions, effectively losing access to their capital.
 * **Mitigation:**
   * **Transparency:** All setPancakePair and DepositToken calls emit on-chain events.
   * **Institutional Reputation:** Security derived from the issuer's legal standing and regulatory oversight.
   * **Contract-Based Redemption:** Official redemption paths are hardcoded, even if DEXs are blocked.
## 4. Security Control Mapping
| Vulnerability Category | Mitigation Mechanism |
|---|---|
| **Reentrancy** | Checks-Effects-Interactions pattern (State updated before transfer). |
| **Access Control** | OpenZeppelin-style onlyOwner and onlyMinter modifiers. |
| **Unauthorized Transfers** | Centralized _beforeTransfer hook (Pause/Blacklist/Freeze). |
| **Logic Bugs** | Monolithic, simple code structure to reduce complexity. |
## 5. Residual Risks
Despite all mitigations, the following risks remain inherent to the design:
 1. **Centralization:** The protocol is functionally a managed database on a blockchain; the owner's power cannot be technically restricted without changing the core business model.
 2. **Oracle Heartbeat:** There is a minor delay between real-world price changes and on-chain updates.
 3. **Third-Party USDT Risk:** If the USDT contract is paused or compromised, tUSD backing is effectively lost.
## 6. Conclusion
The threat model for TetraUSD confirms that the system is **Resilient to External Attacks** but **Highly Vulnerable to Internal Key Compromise**. Therefore, the security of the protocol shifts from smart contract code to **Institutional Key Management and Operational Security (
