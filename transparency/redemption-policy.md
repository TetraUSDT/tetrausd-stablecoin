# Redemption Policy: TetraUSD (tUSD)
This document specifies the terms, conditions, and technical procedures for the redemption of **TetraUSD (tUSD)** tokens for their underlying collateral (USDT or BNB). As a centrally managed stablecoin, redemptions are governed by both smart contract logic and administrative liquidity management.
## 1. Redemption Pathways
TetraUSD provides users with two primary on-chain redemption channels. Each channel is subject to specific technical constraints and liquidity availability.
### 1.1 USDT Redemption (sellForUSDT)
The primary method for maintaining the 1:1 USD peg.
 * **Ratio:** 1 tUSD = 1 USDT (less network gas fees).
 * **Mechanism:** The contract burns the user's tUSD and transfers an equivalent amount of USDT from the contract's balance to the user's wallet.
 * **Prerequisite:** The smart contract must be pre-funded with USDT by the Owner (see Treasury Policy).
### 1.2 BNB Redemption (sellForBNB)
A secondary exit path utilizing native chain liquidity.
 * **Ratio:** Variable, calculated via the Chainlink BNB/USD Oracle.
 * **Mechanism:** The contract burns tUSD and transfers the calculated BNB amount to the user.
 * **Calculation:**
   
## 2. Technical and Security Constraints
Redemptions are not guaranteed at all times and are subject to the following security hooks:
 1. **Global Pause:** If the contract is paused, all redemptions are halted.
 2. **Account Restrictions:** Blacklisted or Frozen addresses cannot initiate redemptions.
 3. **Liquidity Checks:** Transactions will revert with "No liquidity" or "No BNB" if the contract's balance is insufficient to cover the request.
 4. **Satoshi Setting:** Even EIP-712 signed executions for redemptions must pass the _beforeTransfer security filter.
## 3. The "Institutional Buffer" Model
Due to the **Treasury Redirection** model (where minting USDT is moved to a separate vault), the tUSD contract does not automatically hold 100% of the collateral for redemptions.
### 3.1 On-Chain Liquidity Limits
 * **Standard Users:** Can redeem up to the available "Liquidity Buffer" held in the contract balance.
 * **Large-Scale Holders:** For redemptions exceeding the current contract balance, users must coordinate with the Issuer off-chain to trigger a "Treasury-to-Contract" fund transfer.
### 3.2 Redemption Tiers
| Amount (tUSD) | Process | Timeframe |
|---|---|---|
| **< 100,000** | Direct On-chain Redemption | Instant (if liquidity exists) |
| **> 100,000** | Administrative Funding Required | 24 - 48 Hours |
## 4. Market Exit Restrictions (DEX Policy)
The Issuer reserves the right to restrict redemptions through secondary markets.
 * **PancakeSwap Blocking:** If the pancakePair address is set, users cannot "sell" tUSD into the DEX pool.
 * **Rationale:** This ensures that large-scale exits do not cause massive slippage or de-pegging in unmanaged pools, directing all significant volume through the official contract redemption functions where the peg is guaranteed 1:1.
## 5. Fees and Costs
 * **Protocol Fees:** Currently 0% (subject to change via contract update or administrative policy).
 * **Network Fees:** Users are responsible for all BSC gas fees associated with the burn and transfer operations.
 * **Slippage:** 0% on USDT redemptions. BNB redemptions are subject to oracle price fluctuations between transaction broadcast and confirmation.
## 6. Disclaimer of Solvency
While TetraUSD aims to maintain 100% collateralization, the ability to redeem is dependent on:
 1. The solvency of the Issuer's Treasury.
 2. The security of the Owner's Multi-Signature keys.
 3. The availability of the BNB Smart Chain network and Chainlink Oracles.
**The Issuer is not liable for delays in redemption caused by network congestion, oracle failure, or the need for manual treasury rebalancing.**
## 7. Conclusion
The TetraUSD Redemption Policy is designed to balance **User Exit Liquidity** with **Treasury Security**. By utilizing a tiered approach and maintaining administrative control over DEX exits, the protocol ensures an orderly redemption process that protects the 1:1 USD parity for all stakeholders.
