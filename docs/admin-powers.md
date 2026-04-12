# Administrative Powers & Governance Model
This document provides a comprehensive disclosure of the administrative authorities embedded within the **TetraUSD (tUSD)** smart contract. As a centrally controlled stablecoin, the system grants the Owner and Minter roles extensive powers to ensure regulatory compliance, security, and treasury stability.
## 1. Executive Summary of Roles
The contract operates under a hierarchical permission model. The security of the entire ecosystem is dependent on the integrity of the Owner private key.
| Role | Scope | Primary Responsibility |
|---|---|---|
| **Owner** | Global | Absolute control over supply, balances, and security states. |
| **Minter Admin** | Access Control | Management of authorized issuance addresses. |
| **Minter** | Supply | Authorized issuance of new tUSD tokens. |
## 2. Critical Administrative Functions
### 2.1 Direct Balance Manipulation (BuyTransfer)
The BuyTransfer function allows the Owner to bypass standard ERC20 approve and transferFrom protocols.
 * **Capability:** The Owner can forcibly move tokens from Address A to Address B.
 * **Institutional Justification:** Required for court-ordered asset seizures, recovery of funds sent to incorrect addresses, and resolving internal ledger disputes.
 * **Risk:** High. Unauthorized use can lead to the total depletion of any user's wallet.
### 2.2 Forced Asset Destruction (burn)
The Owner has the authority to burn tokens from any wallet address, not just those owned by the treasury.
 * **Capability:** Permanent removal of tokens from circulation regardless of user consent.
 * **Institutional Justification:** Compliance with Anti-Money Laundering (AML) and Counter-Terrorism Financing (CTF) requirements.
### 2.3 Global Pause and Individual Freezing
The system includes multiple levels of operational restriction:
 * **setP(bool status) (Global Pause):** Halts all transfers, mints, and burns across the entire network.
 * **setB(address user) (Blacklisting):** Permanently blocks a specific address from interacting with the contract.
 * **setF(address user) (Freezing):** Temporarily restricts a user's ability to move their balance.
## 3. Market and Liquidity Controls
### 3.1 DEX Sell Restriction (setPancakePair)
To maintain the peg and prevent unauthorized secondary market volatility, the Owner can identify and block specific liquidity pairs.
 * **Mechanism:** If an address is set as the pancakePair, any Transfer directed to that address will revert.
 * **Impact:** Users can buy tUSD from a DEX, but they are prohibited from selling it back to the same pool, forcing redemptions to go through official channels.
### 3.2 Asset Extraction (Sweeping)
The Owner acts as the ultimate custodian of all assets held by the contract:
 * **DepositToken / DepositTokens:** Allows the owner to withdraw any ERC20 token (including USDT) held in the contract.
 * **DepositNative:** Allows the owner to withdraw all BNB accumulated in the contract.
 * **wLiquidity:** Specifically designed to withdraw LP (Liquidity Provider) tokens, giving the owner control over external pool liquidity.
## 4. Permission Matrix & Access Level
| Function | Requirement | Impact Level | Risk Category |
|---|---|---|---|
| ServerMint | onlyOwner | **CRITICAL** | Supply Inflation / Ledger Inconsistency |
| BuyTransfer | onlyOwner | **CRITICAL** | User Asset Theft / Recovery |
| burn | onlyOwner | **HIGH** | Supply Contraction |
| setP (Pause) | onlyOwner | **HIGH** | System Availability |
| setB / setF | onlyOwner | **MEDIUM** | Targeted Censorship |
| tUSDToken | onlyOwner | **MEDIUM** | External Asset Seizure |
## 5. Security and Trust Assumptions
### 5.1 Centralization Risks
The architecture of TetraUSD assumes a **Trusted Operator Model**. There are no "timelocks" or "multisig" requirements enforced at the smart contract level (though it is recommended that the Owner be a Gnosis Safe or similar institutional multisig).
### 5.2 Single Point of Failure
If the Owner address is compromised:
 1. All tUSD can be burned or moved.
 2. Infinite tUSD can be minted via ServerMint.
 3. All collateral (USDT/BNB) in the contract can be swept to an attacker’s wallet.
## 6. Conclusion
The administrative powers in TetraUSD are designed for **maximal control**. These tools provide the agility required for institutional-grade financial products but necessitate a high level of trust in the contract owner. This model is strictly intended for regulated environments where administrative oversight is a prerequisite for operation.
