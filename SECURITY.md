# Security Policy: TetraUSD (tUSD) Infrastructure
This document outlines the security procedures, vulnerability reporting processes, and the structural security model of the **TetraUSD (tUSD)** smart contract. As a centrally managed stablecoin, our security approach combines cryptographic excellence with rigorous administrative oversight.
## 1. Vulnerability Disclosure Policy (VDP)
We value the contributions of the security research community. If you discover a vulnerability within the TetraUSD smart contract or its supporting infrastructure, we request that you report it to us responsibly.
### 1.1 Reporting Process
 * **Contact:** Please send a detailed report to security@tetrausd.io.
 * **Required Information:**
   * A clear description of the vulnerability.
   * Steps to reproduce the issue (PoC code is highly encouraged).
   * Potential impact assessment.
 * **Encryption:** We recommend using PGP encryption for sensitive reports.
### 1.2 "Safe Harbor" Policy
We will not initiate legal action against researchers who:
 * Disclose vulnerabilities privately and provide a reasonable time for remediation.
 * Do not attempt to exploit the vulnerability for personal gain or to damage users.
 * Do not publicly disclose the vulnerability until a fix has been deployed.
## 2. Smart Contract Security Architecture
The TetraUSD contract is engineered with "Defense in Depth" (DiD) principles to ensure the integrity of the ledger.
### 2.1 Role-Based Access Control (RBAC)
The system uses a strict hierarchy of permissions:
 * **Owner (Cold/Multisig):** Access to high-impact functions like BuyTransfer, burn, and wLiquidity.
 * **Minter:** Authorized only for issuance through mint and mintTransfer.
 * **Admin Minter:** Manages the whitelist of authorized minters.
### 2.2 Operational Safeguards (_beforeTransfer)
Every transaction is intercepted by a security hook that validates:
 * **Global Circuit Breaker:** Ability to pause the entire contract.
 * **Account Isolation:** Blacklisting and Freezing capabilities to prevent illicit fund movement.
 * **Market Guard:** Restriction of sell orders to unauthorized DEX pairs (pancakePair).
## 3. Threat Mitigation and Incident Response
In the event of a detected anomaly or security breach, the following "Incident Response Plan" (IRP) is triggered:
### 3.1 Tier 1: Emergency Shutdown
The Owner can immediately call setP(true) to halt all transfers, mints, and burns. This prevents further exploitation while the team investigates.
### 3.2 Tier 2: Asset Isolation
Malicious actors or compromised addresses are identified and added to the blacklisted mapping. This prevents them from moving tUSD or interacting with the contract.
### 3.3 Tier 3: Asset Recovery
Using the BuyTransfer function, the Owner can forcibly retrieve stolen tUSD from a compromised wallet and return it to the treasury or the rightful owner.
## 4. Key Management Standards
The security of TetraUSD is fundamentally dependent on the security of the **Owner private key**.
### 4.1 Multi-Signature Requirements
The Owner address is **NOT** a single-signature (EOA) wallet. It is a **Gnosis Safe Multisig** requiring:
 * **Threshold:** 3-of-5 signatures.
 * **Signers:** Geo-distributed institutional keys, held in hardware security modules (HSMs).
### 4.2 Timelock (Off-chain Policy)
While not enforced at the contract level (to allow for emergency response), all non-emergency administrative actions are subject to an internal 24-hour verification period before the final multisig signature is applied.
## 5. Third-Party Audits
TetraUSD undergoes regular security reviews.
 * **Audit Scope:** Logic flaws, reentrancy, access control, and EIP-712 signature malleability.
 * **Known Limitations:** See audit/known-limitations.md regarding the intentional centralization of the protocol.
## 6. Security Checklist for Users
 * **Official Contract Address:** Always verify the tUSD contract address via our official dashboard.
 * **Phishing Awareness:** TetraUSD administrators will never ask for your private keys or seed phrases.
 * **Signature Verification:** When using the execute function, verify the EIP-712 domain name ("Tetra USD") in your wallet before signing.
## 7. Conclusion
Security at TetraUSD is an ongoing process. We integrate technical excellence with institutional-grade administrative controls to provide a stablecoin environment that is both robust against external attacks and compliant with international standards.
