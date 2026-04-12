# Treasury Management Policy
This document defines the protocols for the management, custody, and rebalancing of collateral assets (USDT and BNB) backing the **TetraUSD (tUSD)** stablecoin.
## 1. Treasury Architecture
The TetraUSD Treasury is designed to decouple **Issuance** from **Custody**. This separation of concerns minimizes "Hot Wallet" risks associated with smart contract vulnerabilities.
### 1.1 The Primary Treasury Address
The treasury address defined in the contract is the primary entry point for all USDT-backed minting.
 * **Mechanism:** All USDT deposited via buyWithUSDT is atomically transferred to this address.
 * **Custody:** This address is a high-security Multi-Signature wallet (Gnosis Safe or equivalent).
### 1.2 Custody Tiers
To optimize between liquidity and security, assets are distributed across three tiers:
 1. **Tier 1 (Contract Balance):** Operational liquidity for immediate redemptions. (High Velocity).
 2. **Tier 2 (Multi-Sig Vault):** Secondary reserves for bulk redemptions. (Medium Velocity).
 3. **Tier 3 (Cold Storage):** Primary collateral backing, held in offline institutional custody. (Low Velocity).
## 2. Asset Allocation and Rebalancing
The Treasury Department is responsible for maintaining the peg through strategic asset allocation.
### 2.1 The Liquidity Buffer
The contract must maintain a "Liquidity Buffer" to satisfy standard user redemptions (sellForUSDT and sellForBNB).
 * **Target Buffer:** 5-10% of the total circulating supply is ideally kept within the smart contract.
 * **Refill Trigger:** If the contract's USDT balance falls below the threshold, the Owner initiates a transfer from Tier 2 (Vault) to the contract.
### 2.2 BNB Volatility Management
Since BNB is a volatile asset used for minting, the Treasury monitors the BNB/USD oracle price.
 * **Sweeping:** Excess BNB accumulated from buyWithBNB is periodically "swept" using DepositNative and converted to USDT to maintain a stable reserve ratio.
## 3. Administrative Asset Recovery (Sweeping)
The Treasury Policy mandates the periodic use of sweeping functions to ensure the smart contract does not become an over-collateralized target for hackers.
 * **ERC20 Sweeping:** Any non-tUSD tokens (primarily USDT) accumulated in the contract are swept to the Treasury.
 * **LP Token Recovery:** LP tokens earned or deposited in the contract are moved to the Treasury to ensure the Issuer maintains control over secondary market depth.
## 4. Operational Risk Controls
### 4.1 Internal Controls
 * **Separation of Duties:** The individual(s) initiating a "Sweep" or "Transfer" cannot be the same individual(s) who approve the final Multi-Sig transaction.
 * **Withdrawal Limits:** Off-chain administrative policies dictate daily limits for transfers from Tier 2 to Tier 1, unless an emergency liquidity event is declared.
### 4.2 Emergency Liquidity Protocol
In the event of a mass redemption ("Bank Run"), the Treasury follows these steps:
 1. **Pause System:** setP(true) is called to stabilize the peg.
 2. **Collateral Liquidation:** Tier 3 (Cold Storage) assets are moved to Tier 1.
 3. **Orderly Exit:** The system is unpaused, and redemptions are processed in batches.
## 5. Transparency and Reporting
The Treasury provides visibility into the backing of tUSD through:
 * **On-chain Monitoring:** Publicly disclosed Treasury and Vault addresses.
 * **Proof of Reserves:** Periodic attestations (internal or third-party) matching total tUSD balances with aggregate Treasury assets.
## 6. Conclusion
The TetraUSD Treasury Policy prioritizes **Security and Solvency** over decentralization. By utilizing a multi-tiered custody model and active redirection of assets, the Treasury ensures that the 1:1 USD peg is backed by verifiable, securely held collateral, while maintaining the flexibility to respond to market volatility or regulatory requirements.
