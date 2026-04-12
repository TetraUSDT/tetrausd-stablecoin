# Risk Disclosure Statement: TetraUSD (tUSD)
This document outlines the critical risks associated with the **TetraUSD (tUSD)** stablecoin. Prospective users, institutional partners, and liquidity providers must review and acknowledge these risks before interacting with the protocol.
**TetraUSD is a Centrally Controlled Stablecoin Infrastructure. It is NOT a decentralized, permissionless, or algorithmic protocol.**
## 1. Centralization and Governance Risk (Critical)
The most significant risk factor for tUSD is its **Centralized Authority Model**. The contract grants the Owner absolute power over the ledger.
 * **Administrative Intervention:** The Owner can forcibly transfer tokens from any wallet (BuyTransfer), burn tokens in any wallet (burn), or freeze any account (setF).
 * **Single Point of Failure:** The security of the entire ecosystem is dependent on the integrity of the Owner’s private key. If this key is compromised, an attacker could mint infinite tokens, drain collateral, or wipe user balances.
 * **Lack of Timelocks:** Administrative actions are executed immediately upon transaction confirmation, without on-chain delay or community voting mechanisms.
## 2. Liquidity and Redemption Risk
Unlike Automated Market Makers (AMMs), tUSD relies on a **Direct-to-Contract** redemption model.
 * **Treasury Redirection:** USDT used to purchase tUSD is redirected to a treasury address and is not held within the smart contract.
 * **Redemption Dependency:** The sellForUSDT function only works if the Owner manually funds the contract with USDT. There is no on-chain guarantee that the contract will always have sufficient liquidity for immediate redemptions.
 * **DEX Exit Restriction:** The Owner can block the selling of tUSD on PancakeSwap via the pancakePair setter. This may "trap" funds within a wallet, forcing users to rely solely on the issuer for liquidation.
## 3. Technical and Accounting Risk
The architecture includes non-standard ERC20 behaviors that may affect third-party integrations.
 * **ServerMint Inconsistency:** The ServerMint function credits user balances without updating the totalSupply. This creates a deliberate discrepancy where the sum of all balances exceeds the reported total supply.
 * **Oracle Dependency:** The buyWithBNB and sellForBNB functions depend on the Chainlink BNB/USD price feed. If the oracle provides stale data, experiences a delay, or is manipulated, users may mint or redeem tokens at unfavorable rates.
 * **Non-Upgradeable Logic:** The contract is immutable. Any logic error or vulnerability discovered post-deployment cannot be patched. A full migration to a "V2" contract would be required.
## 4. Regulatory and Censorship Risk
TetraUSD is designed to be fully compliant with international financial regulations, which introduces censorship risk.
 * **Blacklisting:** The issuer can blacklist any address (e.g., to comply with OFAC sanctions or law enforcement orders), rendering the tUSD in that wallet untransferable and unredeemable.
 * **Jurisdictional Risk:** The issuer operates under specific legal jurisdictions. Changes in stablecoin regulations could lead to the sudden freezing of the protocol or mandatory changes in the redemption policy.
## 5. Asset Recovery and Sweeping Risk
The Owner acts as the ultimate custodian of all assets held by the smart contract.
 * **Sweeping Functions:** The Owner can use DepositNative and DepositToken to withdraw all BNB and ERC20 tokens (including collateral) from the contract balance at any time.
 * **Third-Party Pulls:** The tUSDToken function allows the Owner to pull other tokens from a user’s wallet if an allowance has been previously granted to the tUSD contract.
## 6. Summary of Risk Tiers
| Risk Category | Level | Impact |
|---|---|---|
| **Centralization** | **Extreme** | Absolute control by Owner; no user sovereignty. |
| **Liquidity** | **High** | Subject to manual funding and DEX sell blocks. |
| **Oracle** | **Medium** | Dependent on Chainlink feed availability/accuracy. |
| **Accounting** | **Medium** | totalSupply may not reflect circulating supply. |
## 7. Conclusion and Acknowledgment
By holding or interacting with **TetraUSD (tUSD)**, you acknowledge that you have read and understood these risks. You agree that the project’s value and functionality are fundamentally tied to the administrative decisions and operational security of the contract Owner.
**USE AT YOUR OWN RISK.** This software is provided "as is" without any warranties regarding its financial performance or the permanence of its liquidity.
*Last Updated: April 2026*
