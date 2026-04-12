# Transfer Restrictions and Compliance Controls
This document specifies the internal logic and administrative filters applied to token movements within the **TetraUSD (tUSD)** smart contract. To maintain institutional integrity and regulatory compliance, tUSD does not operate as a permissionless asset.
## 1. The Security Hook: _beforeTransfer
Every standard interaction—including transfer, transferFrom, and execute (EIP-712)—is subject to a mandatory pre-execution check. This hook ensures that the transaction complies with the current security state of the network.
### 1.1 Validation Logic
Before any balance update, the contract verifies:
 * The global paused state is false.
 * Neither the sender nor the recipient is in the blacklisted mapping.
 * Neither the sender nor the recipient is in the frozen mapping.
 * The recipient is not the restricted pancakePair address.
## 2. Administrative Restriction Tiers
The Owner has the authority to restrict movement at three distinct levels:
### 2.1 Global Pause (setP)
When the contract is paused, **all** non-owner-initiated transfers are halted.
 * **Purpose:** Emergency response to smart contract vulnerabilities or extreme market instability.
 * **Scope:** Affects all users globally.
### 2.2 Blacklisting (setB)
An address added to the blacklist is permanently barred from the ecosystem.
 * **Incoming:** The address cannot receive tUSD.
 * **Outgoing:** The address cannot send tUSD.
 * **Purpose:** Compliance with international sanctions (e.g., OFAC) and law enforcement requests.
### 2.3 Freezing (setF)
Freezing is a targeted restriction that prevents a specific user from moving their funds while still allowing the ledger to reflect their balance.
 * **Purpose:** Anti-fraud measures and internal investigation periods.
## 3. Secondary Market Control (DEX Sell Block)
A unique feature of TetraUSD is the ability to programmatically restrict exit liquidity on Decentralized Exchanges (DEXs).
### 3.1 pancakePair Restriction
The Owner can identify the official liquidity pool address (e.g., tUSD/BNB pair on PancakeSwap) using setPancakePair.
 * **Logic:** The contract intercepts any transfer where to == pancakePair and reverts the transaction with the error "DEX SELL BLOCKED".
 * **Implications:** Users can purchase tUSD from the pool (as they are the recipient), but they are prohibited from selling tUSD back into the pool.
 * **Rationale:** This forces high-volume redemptions to occur through the official sellForUSDT or sellForBNB functions, allowing the issuer to manage reserves and maintain the peg manually.
## 4. Administrative Overrides
It is critical to note that **Administrative Transfers** are exempt from standard restrictions.
### 4.1 BuyTransfer Bypass
The BuyTransfer function, callable only by the Owner, does not trigger the _beforeTransfer hook.
 * **Effect:** The Owner can move funds even if the contract is paused or if the accounts involved are blacklisted/frozen.
 * **Design Choice:** This ensures the issuer always maintains "Ultimate Control" over the ledger for recovery and compliance purposes.
## 5. Summary of Restrictions Table
| Restriction Type | Triggered By | Affects transfer | Affects BuyTransfer |
|---|---|---|---|
| **Global Pause** | paused = true | Blocked | **Allowed** |
| **Blacklist** | blacklisted[user] | Blocked | **Allowed** |
| **Freeze** | frozen[user] | Blocked | **Allowed** |
| **DEX Sell Block** | to == pancakePair | Blocked | **Allowed** |
## 6. Risk Disclosure for Users
Users of TetraUSD must acknowledge that their ability to transfer or liquidate their holdings is **conditional**.
 1. **Censorship Risk:** The issuer can prevent any user from moving funds at their sole discretion.
 2. **Liquidity Trap:** The DEX Sell Block can effectively "trap" funds within a wallet if the official redemption functions are underfunded or disabled.
 3. **No Absolute Privacy:** Since all transfers are subject to admin-defined rules, the asset does not provide the same level of censorship resistance as native BNB or decentralized stablecoins.
## 7. Conclusion
The transfer restriction architecture of TetraUSD is designed for **maximum oversight**. By combining global, individual, and market-level blocks, the protocol provides the necessary tools for an institutional operator to manage a regulated digital asset environment.
