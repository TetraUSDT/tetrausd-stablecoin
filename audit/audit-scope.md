# Audit Scope: TetraUSD (tUSD) Stablecoin
This document defines the technical scope, objectives, and high-priority targets for the security audit of the **TetraUSD (tUSD)** smart contract. Auditors are expected to evaluate the contract for logic flaws, security vulnerabilities, and adherence to the specified centralization model.
## 1. Project Identity
 * **Project Name:** TetraUSD
 * **Token Symbol:** tUSD
 * **Contract Language:** Solidity ^0.8.24
 * **Network:** BNB Smart Chain (BSC)
 * **Compiler Settings:** Optimization enabled (200 runs)
## 2. Audit Objectives
The primary goal of this audit is to identify:
 1. **Security Vulnerabilities:** Reentrancy, Overflow/Underflow (pre-0.8.x style), Timestamp dependence, and Flash Loan attack vectors.
 2. **Access Control Integrity:** Ensuring that onlyOwner and onlyMinter modifiers are correctly applied and cannot be bypassed.
 3. **Logical Consistency:** Verifying that the hybrid minting (USDT/BNB) and redemption logic functions as intended.
 4. **Centralization Risk Assessment:** Documenting the impact of "God Mode" functions on user funds.
 5. **Signature Malleability:** Evaluating the EIP-712 execute function for replay attack resistance.
## 3. Technical Scope (In-Scope Files)
The audit is strictly limited to the following core contract:
| File | Type | SLOC | Description |
|---|---|---|---|
| contracts/TetraUSD.sol | Core Logic | ~450 | Implementation of ERC20, Mint/Burn, Oracle, and Admin controls. |
### External Dependencies (Out-of-Scope)
 * **USDT Contract:** Standard BEP-20 implementation.
 * **Chainlink Oracle:** AggregatorV3Interface (Auditors should assume the oracle returns data correctly but check for stale data handling).
 * **PancakeSwap Router/Factory:** External DEX infrastructure.
## 4. High-Priority Audit Targets
Auditors should pay particular attention to the following functions and logic flows:
### 4.1 Administrative Overrides
 * **BuyTransfer()**: Ability to move funds without allowance. Does it bypass the _beforeTransfer security hook?
 * **burn()**: Ability to destroy tokens in any wallet.
 * **tUSDToken()**: Direct transferFrom call on external tokens (USDT).
### 4.2 The "Ghost Supply" Logic
 * **ServerMint()**: This function increases balanceOf but NOT totalSupply. Auditors must evaluate the systemic risk of this accounting discrepancy for third-party integrations (Lending protocols, DEXs).
### 4.3 Hybrid Issuance/Redemption
 * **buyWithBNB() / sellForBNB()**: Mathematical accuracy of the Oracle-based conversion.
 * **buyWithUSDT()**: Ensuring the atomic redirection to the treasury address is gas-efficient and secure.
### 4.4 Meta-Transactions
 * **execute()**: Verification of the EIP-712 signature, nonce incrementation, and deadline enforcement. Check for signature malleability (v, r, s values).
### 4.5 Security Hooks
 * **_beforeTransfer()**: Evaluation of the conditional logic for paused, blacklisted, frozen, and the pancakePair sell-block.
## 5. Potential Attack Vectors to Test
 * **Reentrancy:** Check sellForBNB and sellForUSDT for state updates before external transfers.
 * **Front-running:** Evaluating if an admin can front-run a large buyWithBNB by changing the Oracle address (though Oracle address is currently immutable, check for similar vectors).
 * **Denial of Service (DoS):** Can a blacklisted user brick the Transfers (batch) function if they are included in the recipient list?
 * **Signature Replay:** Can a signature used on a Testnet be replayed on the BSC Mainnet? (Check DOMAIN_SEPARATOR and chainId).
## 6. Known Limitations (Non-Vulnerabilities)
The following behaviors are **intentional** and should be noted but not flagged as "bugs" unless a bypass is found:
 1. **Centralization:** The owner has absolute control (Mint, Burn, Transfer, Pause).
 2. **Supply Desync:** totalSupply does not reflect the sum of all balances.
 3. **Liquidity Dependence:** Redemptions rely on manual funding of the contract.
## 7. Delivery Requirements
Auditors are required to provide:
 1. **Vulnerability List:** Categorized by severity (Critical, High, Medium, Low, Informational).
 2. **PoC (Proof of Concept):** For all Critical and High findings.
 3. **Remediation Guidance:** Specific code changes to fix the identified issues.
 4. **Gas Optimization:** Suggestions for reducing operational costs for admin/user functions.
