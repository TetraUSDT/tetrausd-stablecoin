# Reserve Model and Proof of Reserve (PoR)
This document outlines the asset backing, collateralization ratios, and transparency protocols for **TetraUSD (tUSD)**. To maintain institutional trust, tUSD operates under a **Hybrid Reserve Model** with real-time on-chain tracking.
## 1. Collateral Composition
TetraUSD is backed by a combination of stable liquid assets and native chain liquidity. The reserve is designed to ensure a 1:1 parity with the US Dollar at all times.
### 1.1 Primary Reserve (USDT)
 * **Type:** BEP-20 USDT.
 * **Ratio:** Aimed at \ge 100\% backing for all tUSD issued via buyWithUSDT.
 * **Storage:** Assets are redirected to the treasury address upon minting to be moved into institutional cold storage or multi-sig vaults.
### 1.2 Secondary Reserve (BNB)
 * **Type:** Native BNB.
 * **Ratio:** Variable, based on the Chainlink Oracle price at the time of minting.
 * **Storage:** Held within the tUSD smart contract balance to facilitate automated sellForBNB redemptions.
## 2. Proof of Reserve (PoR) Methodology
Verification of tUSD reserves requires monitoring multiple on-chain and off-chain data points due to the centralized nature of the treasury.
### 2.1 Calculating Total Liabilities (Total Supply)
To find the actual circulating supply of tUSD, auditors must look beyond the totalSupply variable due to the ServerMint function.
 * **Reported Supply:** Accessible via totalSupply().
 * **Actual Supply:** Calculated by summing all balanceOf mappings or aggregating all Transfer events from the 0x00...0 address.
### 2.2 Calculating Total Assets
The total backing is the sum of:
 1. **Contract USDT Balance:** USDT held in the tUSD contract for immediate redemptions.
 2. **Treasury USDT Balance:** USDT held in the official treasury address (and associated cold wallets).
 3. **Contract BNB Balance:** Native BNB held in the tUSD contract.
## 3. Treasury Redirection Flow
The redirection of USDT is a strategic security and management choice.
 1. **User Deposit:** User sends 100 USDT to buyWithUSDT.
 2. **Atomic Move:** The contract moves 100 USDT directly to the treasury.
 3. **Minting:** 100 tUSD is minted to the user.
 4. **Verification:** An auditor can see the 100 USDT increase in the treasury address and the corresponding 100 tUSD mint event on the same block.
## 4. Reserve Management Policy
### 4.1 Rebalancing
The Issuer periodically rebalances the reserves to ensure that redemptions can be met in both USDT and BNB.
 * If BNB reserves are low, the Issuer may convert Treasury USDT to BNB and deposit it into the contract.
 * If USDT redemption liquidity is low, the Issuer manually funds the contract from the Treasury.
### 4.2 The "Sweeping" Clause
As disclosed in the RISK_DISCLOSURE.md, the Owner has the right to sweep all assets from the contract to the Treasury. In such events, the **Total Assets** calculation must include the balance of the Treasury's secure vaults to confirm the 1:1 backing remains intact.
## 5. Transparency Metrics
| Metric | Source | Frequency |
|---|---|---|
| **Circulating tUSD** | On-chain (Sum of Balances) | Real-time |
| **USDT Reserve** | Treasury + Contract Balance | Real-time |
| **BNB Reserve** | Contract Balance | Real-time |
| **Oracle Price** | Chainlink BNB/USD Feed | Real-time |
## 6. Audit Guidelines for Institutions
Institutional partners are encouraged to run independent indexing nodes to track the **Actual Supply vs. Reserve Assets**.
> **Audit Note:** Any significant delta where **Total Assets < Actual Supply** (total of all balances) indicates an under-collateralization event, unless the Issuer provides proof of off-chain fiat/cash-equivalent reserves.
> 
## 7. Conclusion
The TetraUSD Reserve Model is designed for **High Velocity and Institutional Oversight**. By combining on-chain USDT redirection with automated BNB oracle-based minting, the protocol provides a transparent, yet administratively flexible, backing system that supports the 1:1 USD peg.
