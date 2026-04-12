# High-Risk Functions Analysis (Internal Audit)
This document identifies and analyzes the functions within the **TetraUSD (tUSD)** smart contract that possess the highest degree of privilege and potential for system-wide impact. These functions represent the "Centralization Vector" of the protocol and must be the primary focus of any third-party security review.
## 1. Administrative Asset Manipulation
### 1.1 BuyTransfer(address from, address to, uint256 amount)
 * **Access Control:** onlyOwner
 * **Risk Level:** **CRITICAL**
 * **Technical Impact:** Bypasses the standard ERC-20 allowance and approve mechanism. The Owner can move tokens from any wallet to any other wallet without the user's signature or consent.
 * **Audit Note:** This function does not trigger the _beforeTransfer hook in its current implementation, meaning it can bypass paused, blacklisted, and frozen states.
 * **Justification:** Required for court-ordered asset recovery and reversing fraudulent transactions.
### 1.2 burn(address from, uint256 amount)
 * **Access Control:** onlyOwner
 * **Risk Level:** **HIGH**
 * **Technical Impact:** Allows the permanent destruction of tUSD tokens held in any address.
 * **Audit Note:** Improper use or private key compromise would lead to the total loss of user funds without the possibility of recovery.
## 2. Supply and Ledger Inconsistency
### 2.1 ServerMint(address to, uint256 amount)
 * **Access Control:** onlyOwner
 * **Risk Level:** **CRITICAL**
 * **Technical Impact:** Directly increments balanceOf[to] but **explicitly fails to update totalSupply**.
 * **Audit Note:** This creates a fundamental accounting discrepancy on the blockchain.
   * sum(all_balances) > totalSupply.
   * External DeFi protocols, dashboard aggregators, and exchanges that rely on the totalSupply() constant will receive inaccurate data regarding the circulating supply.
 * **Risk:** "Ghost Supply" creation.
## 3. Liquidity and Exit Control
### 3.1 setPancakePair(address _pancakePair)
 * **Access Control:** onlyOwner
 * **Risk Level:** **HIGH**
 * **Technical Impact:** Identifies a specific address (typically the DEX liquidity pool) to be restricted via the _beforeTransfer hook.
 * **Audit Note:** By setting this address, the Owner can effectively "trap" user funds by preventing them from selling tUSD on the secondary market.
 * **Risk:** Liquidity lockout for retail users.
### 3.2 wLiquidity(address lp, uint256 amount)
 * **Access Control:** onlyOwner
 * **Risk Level:** **MEDIUM/HIGH**
 * **Technical Impact:** Allows the Owner to withdraw LP (Liquidity Provider) tokens held by the contract.
 * **Audit Note:** If the contract itself provides liquidity to a DEX, the Owner can remove that liquidity at any time, causing massive slippage for users.
## 4. Asset Recovery and Sweeping
### 4.1 DepositToken / DepositNative
 * **Access Control:** onlyOwner
 * **Risk Level:** **HIGH**
 * **Technical Impact:** Allows the Owner to drain all ERC-20 tokens (including USDT collateral) and native BNB from the contract.
 * **Audit Note:** Since the sellForUSDT and sellForBNB functions rely on the contract's balance, "sweeping" these assets effectively disables the redemption mechanism.
## 5. Summary Risk Matrix for Auditors
| Function | Type | State Impact | Risk Summary |
|---|---|---|---|
| **BuyTransfer** | Asset Move | Balance Change | Unauthorized fund seizure. |
| **ServerMint** | Issuance | Ledger Desync | Hidden supply / Inflation. |
| **burn** | Destruction | Supply Decrease | Arbitrary balance deletion. |
| **tUSDToken** | Pull | External Asset | Pulling USDT from users' wallets. |
| **setP** | Pause | Availability | Total system halt (Denial of Service). |
## 6. Auditor Recommendations
 1. **Multisig Verification:** It is imperative that the Owner address be a Multi-Signature wallet with geo-distributed signers to mitigate the "Single Point of Failure" risk associated with these functions.
 2. **Event Monitoring:** All high-risk functions emit events (e.g., Transfer, LiquidityWithdrawn). Auditors must set up real-time monitoring to alert stakeholders whenever these functions are called.
 3. **Accounting Reconciliation:** Off-chain tools must be used to reconcile the actual circulating supply (sum of balances) against the reported totalSupply.
## 7. Conclusion
The high-risk functions in TetraUSD are **intentional design choices** to facilitate an institutional-grade managed stablecoin. However, from a technical security perspective, they represent significant centralization vectors that require absolute trust in the contract 
