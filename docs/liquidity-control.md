# Liquidity Control and Asset Management
This document details the mechanisms for liquidity management, collateral redirection, and administrative asset recovery within the **TetraUSD (tUSD)** infrastructure. Unlike decentralized protocols, tUSD centralizes liquidity oversight to empower the issuer with treasury agility.
## 1. Collateral Redirection (Treasury Model)
To minimize on-chain hot-wallet risks and enable institutional fund management, tUSD employs an immediate redirection model for USDT deposits.
### 1.1 The Treasury Flow
When a user interacts with buyWithUSDT(uint256 amount):
 1. The contract calls USDT.transferFrom(msg.sender, treasury, amount).
 2. The collateral bypasses the tUSD smart contract entirely and lands in the treasury address.
 3. **Rationale:** This allows the issuer to move USDT into cold storage, multisig vaults, or yield-generating institutional accounts immediately upon receipt.
## 2. LP Token Management (wLiquidity)
The contract includes specialized functions to manage positions in Decentralized Exchanges (DEXs) such as PancakeSwap.
### 2.1 Withdrawal of Liquidity
The wLiquidity(address lp, uint256 amount) function allows the **Owner** to extract Liquidity Provider (LP) tokens held by the contract.
 * **Mechanism:** Transfers any specified lp token from the contract’s balance directly to the owner's wallet.
 * **Strategic Use:** This is used to migrate liquidity between different DEX versions or to consolidate liquidity during a protocol decommission.
## 3. Asset Sweeping (The Deposit Functions)
To ensure no capital is "trapped" within the smart contract, a robust sweeping system is implemented.
### 3.1 ERC20 Sweeping (DepositToken & DepositTokens)
The Owner can recover any ERC20 tokens sent to the contract (either intentionally or by mistake).
 * **DepositToken(address token, address to)**: Sweeps the entire balance of a specific token to a destination address.
 * **DepositTokens(address[] tokens, address to)**: A batch version for multi-asset recovery in a single transaction.
### 3.2 Native Asset Sweeping (DepositNative)
Any BNB accumulated in the contract (primarily from buyWithBNB calls) can be extracted.
 * **Function:** DepositNative(address to)
 * **Impact:** Moves the entire address(this).balance to the specified recipient.
## 4. Forced External Transfer (tUSDToken)
A high-privilege function, tUSDToken, allows the Owner to move assets that are held by other addresses, provided the tUSD contract has an allowance.
 * **Logic:** IERC20(token).transferFrom(from, treasury, amount)
 * **Purpose:** This is an administrative tool to pull collateral from a user's wallet into the treasury if a pre-approved "Pull" agreement exists off-chain.
## 5. Liquidity Risk Matrix
| Capability | Controlled By | Impact on Users |
|---|---|---|
| **USDT Redirection** | Automatic | Minimal (Internal accounting) |
| **Native Sweep** | onlyOwner | High (Can empty redemption reserves) |
| **LP Withdrawal** | onlyOwner | High (Can remove secondary market depth) |
| **Manual Sell Funding** | onlyOwner | Critical (Required for sellForUSDT to function) |
## 6. Institutional Redemptions and Reserves
Because buy-side USDT is redirected to the treasury, the sellForUSDT function depends on the **Contract Balance**, not the **Treasury Balance**.
 * **Redemption Requirement:** For users to successfully call sellForUSDT, the Owner must manually fund the contract with USDT from the treasury.
 * **Operational Policy:** The issuer typically maintains a "buffer" of liquidity in the contract for small redemptions, while large-scale exits are processed through a manual request-and-fund cycle.
## 7. Conclusion
The liquidity architecture of TetraUSD is designed for **Treasury Efficiency**. By redirecting deposits and providing comprehensive sweeping tools, the protocol ensures the issuer has total control over the underlying collateral. This model necessitates that users trust the issuer's ability and willingness to maintain sufficient "buffer" liquidity for on-chain redemptions.
**Sənəd hazırdır.** Hansı sənəd ilə davam edək? (Məsələn: security-model.md və ya blacklist-freeze-policy.md)
