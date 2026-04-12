# TetraUSD (tUSD): A Centrally Controlled, Institutional-Grade Stablecoin Infrastructure
**Official Technical Whitepaper v1.0**
## Abstract
This whitepaper outlines the technical architecture, economic model, and compliance framework of **TetraUSD (tUSD)**, a fiat-pegged stablecoin deployed on the BNB Smart Chain (BSC). Unlike decentralized algorithmic or over-collateralized stablecoins, tUSD is explicitly designed as a **Centrally Controlled Stablecoin Infrastructure**. It provides a 1:1 USD-pegged digital asset backed by a hybrid reserve of USDT and native BNB. The protocol integrates comprehensive administrative controls—including account freezing, forced asset recovery, and secondary market liquidity restrictions—to ensure strict adherence to Anti-Money Laundering (AML) standards, legal compliance, and institutional treasury requirements.
## 1. Introduction
The rapid expansion of decentralized finance (DeFi) has highlighted a fundamental tension between permissionless architecture and regulatory compliance. Institutional participants, government bodies, and regulated exchanges require digital assets that offer the speed and transparency of blockchain ledgers without sacrificing the administrative oversight necessary to prevent financial crime.
TetraUSD (tUSD) addresses this requirement by merging standard BEP-20 token utility with an embedded "Managed Ledger" framework. It does not attempt to achieve trustless decentralization. Instead, it codifies a unilateral authority model where a designated "Owner" retains absolute control over the asset's lifecycle, issuance, and transferability.
### 1.1 Core Objectives
 * **Price Stability:** Maintain a strict 1:1 peg with the US Dollar through direct collateralization and oracle-based minting.
 * **Regulatory Compliance:** Provide the technical capability to blacklist addresses, freeze funds, and execute forced transfers to comply with legal mandates.
 * **Treasury Agility:** Isolate deposited collateral from the smart contract to enable institutional cold-storage custody.
 * **Meta-Transaction Support:** Facilitate gasless transfers for end-users via the EIP-712 signature standard.
## 2. System Architecture
The TetraUSD smart contract is built on Solidity ^0.8.24 and operates as a monolithic state machine. This architectural choice minimizes the attack surface associated with complex proxy patterns or multi-contract dependencies.
### 2.1 The Security Gatekeeper: _beforeTransfer Hook
At the core of the tUSD architecture is the internal _beforeTransfer hook. Every standard token movement (including EIP-712 executions) is intercepted and evaluated against the current state variables. A transaction will revert if:
 * The global paused state is activated.
 * The sender or recipient is flagged in the blacklisted mapping.
 * The sender or recipient is flagged in the frozen mapping.
 * The recipient address matches the restricted pancakePair address (DEX Sell Block).
### 2.2 Access Control Hierarchy
The protocol relies on a rigid Role-Based Access Control (RBAC) model:
 * **Owner:** The ultimate authority. Capable of bypassing the _beforeTransfer hook via administrative functions, altering global states, sweeping assets, and managing secondary market liquidity.
 * **Minter Admin:** Authorized to grant or revoke minting privileges.
 * **Minter:** Authorized to issue new tokens into circulation.
## 3. Minting and Redemption Mechanisms
TetraUSD employs a dual-pathway system for issuance and redemption, utilizing both stable and volatile assets to ensure deep primary market liquidity.
### 3.1 USDT-Based Operations (1:1 Peg)
Users can mint tUSD at an exact 1:1 ratio using BEP-20 USDT.
 * **Issuance (buyWithUSDT):** When a user deposits USDT, the contract does not hold the funds. Instead, it utilizes transferFrom to atomicaly redirect the USDT to an off-chain treasury address.
 * **Redemption (sellForUSDT):** Users can burn tUSD to reclaim USDT. Because deposits are redirected to the treasury, this function relies entirely on the Owner maintaining a sufficient "Liquidity Buffer" within the contract's actual balance.
### 3.2 Native Asset Operations (Oracle-Based)
Users can mint tUSD using native BNB. To determine the correct exchange rate, the contract integrates the Chainlink AggregatorV3Interface.
 * **Price Discovery:** The contract queries the BSC Chainlink BNB/USD feed.
 * **Issuance Formula:** 
 * **Redemption Formula:**
   
 * *Note:* The 10^{20} scaling factor normalizes the 8-decimal Chainlink response and the 18-decimal BNB input to match the 6-decimal precision of tUSD.
### 3.3 The ServerMint Function (Critical Accounting Feature)
The protocol includes a highly specialized administrative function known as ServerMint. This function allows the Owner to increase a user's balanceOf **without** updating the global totalSupply variable.
 * **Rationale:** Designed for off-chain ledger synchronization, allowing the issuer to credit users based on fiat wire transfers without exposing the total institutional debt on-chain.
 * **Systemic Implication:** The mathematical invariant Sum(\text{Balances}) == \text{TotalSupply} is intentionally broken. Third-party auditors and indexers must calculate the circulating supply by summing individual balances rather than relying on the standard ERC-20 totalSupply() getter.
## 4. Treasury and Liquidity Control
Unlike decentralized stablecoins where collateral is locked in trustless smart contracts, TetraUSD operates on a "Discretionary Management" model.
### 4.1 Asset Sweeping
The Owner possesses the authority to extract any value held within the smart contract.
 * DepositToken / DepositTokens: Sweeps designated ERC-20 tokens (including USDT) to a specified address.
 * DepositNative: Sweeps all accumulated BNB to a specified address.
   This ensures no capital is trapped, but it introduces a dependency on the issuer to manually fund the contract for user redemptions.
### 4.2 DEX Liquidity Management
 * **LP Token Withdrawal:** The wLiquidity function allows the Owner to withdraw Liquidity Provider (LP) tokens directly from the contract, granting the issuer full control over secondary market depth.
 * **The DEX Sell Block:** By setting the pancakePair address, the Owner blocks standard users from executing sell orders on decentralized exchanges. This controversial but necessary feature prevents massive slippage, protects the peg in unmanaged pools, and forces redemptions through the official, KYC-compliant contract channels.
## 5. Compliance and Administrative Authorities
TetraUSD integrates powerful administrative tools designed to satisfy the rigorous demands of global financial regulators. These features represent the primary centralization vectors of the protocol.
### 5.1 Account Censorship
 * **Blacklisting:** Permanently disables an address from sending or receiving tUSD.
 * **Freezing:** Temporarily halts token mobility for a specific address, typically utilized during active fraud investigations.
### 5.2 Forced Asset Interventions
Standard ERC-20 tokens require a user to cryptographically sign an approve transaction before a third party can move their funds. TetraUSD bypasses this requirement for the Owner.
 * **Forced Transfer (BuyTransfer):** The Owner can deduct tUSD from any address and credit it to another address without user consent. This is implemented for court-ordered asset seizures, recovery of stolen funds, and resolution of routing errors.
 * **Forced Burn (burn):** The Owner can permanently destroy tokens residing in any user's wallet.
 * **External Token Pull (tUSDToken):** The Owner can pull external BEP-20 assets from a user's wallet, provided the user has previously granted an allowance to the tUSD contract.
## 6. Gasless Meta-Transactions (EIP-712)
To reduce friction for non-crypto-native institutional clients, TetraUSD supports gasless transactions.
### 6.1 The execute Function
Users can sign a cryptographic message off-chain detailing the recipient, amount, a unique user nonce, and an expiration deadline. A third-party "Relayer" submits this signature to the blockchain and pays the BNB gas fee.
### 6.2 Security Integrity
The execute function strictly implements the _beforeTransfer hook. Therefore, a user cannot use a gasless transaction to bypass a freeze, a blacklist, or the DEX sell restriction. Furthermore, the EIP-712 Domain Separator binds the signature to the specific BSC Chain ID and contract address, neutralizing cross-chain replay attacks.
## 7. Risk Disclosures and Trust Assumptions
Institutions, exchanges, and retail users interacting with TetraUSD must fully understand the operational risks inherent in its design.
 1. **Ultimate Counterparty Risk:** The protocol relies entirely on the operational security and honesty of the Owner. If the Owner's private keys are compromised, the entire ecosystem can be drained, inflated, or permanently frozen.
 2. **Liquidity Dependency:** Because USDT deposits are redirected to an off-chain treasury, the ability of a user to redeem tUSD for USDT via the smart contract is not mathematically guaranteed; it is dependent on the issuer's active liquidity management.
 3. **Oracle Vulnerability:** While Chainlink is robust, extreme volatility or temporary network outages could result in unfavorable exchange rates during BNB-based minting and redemption.
 4. **Accounting Opacity:** Due to ServerMint, the on-chain totalSupply variable cannot be trusted as an accurate reflection of total circulating debt.
## 8. Conclusion
TetraUSD (tUSD) is a pragmatic infrastructure solution bridging the gap between blockchain efficiency and traditional financial compliance. By sacrificing decentralization and permissionless operation, the protocol achieves total administrative oversight. The embedded tools for asset recovery, account restriction, and treasury redirection make tUSD a highly effective, controlled ledger for regulated environments. Evaluators must approach tUSD not as a decentralized protocol, but as a heavily managed, institutional financial product secured by smart contract technology.
