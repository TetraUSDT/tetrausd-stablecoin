# Blacklist and Freeze Policy (Compliance Specification)
This document defines the administrative protocols for restricting individual account access within the **TetraUSD (tUSD)** network. These features are integrated to fulfill regulatory obligations, prevent financial crimes, and facilitate asset recovery.
## 1. Regulatory Necessity
As a centralized stablecoin, TetraUSD must adhere to global financial standards, including:
 * **AML/CFT:** Anti-Money Laundering and Counter-Terrorism Financing.
 * **OFAC Compliance:** Adherence to international sanctions lists.
 * **Law Enforcement Support:** Capability to freeze assets subject to judicial orders or active investigations.
## 2. Technical Implementation
The restriction logic is managed through two distinct state mappings: blacklisted and frozen.
### 2.1 Blacklisting (setB)
When an address is added to the blacklist:
 * **Outgoing Transfers:** Blocked. The user cannot send tUSD.
 * **Incoming Transfers:** Blocked. Other users cannot send tUSD to the blacklisted address.
 * **Standard Redemption:** Blocked. The user cannot call sellForUSDT or sellForBNB.
### 2.2 Freezing (setF)
When an address is frozen:
 * **Operational Status:** Similar to blacklisting, all transfer-related activities are halted.
 * **Purpose:** Typically used for temporary measures during fraud investigations or pending verification of a user's identity (KYC/KYB).
## 3. Comparison of Account Restrictions
| Feature | Blacklisted | Frozen |
|---|---|---|
| **Can Send tUSD** | No | No |
| **Can Receive tUSD** | No | No |
| **Visibility on Chain** | Yes | Yes |
| **Typical Duration** | Permanent (Sanction-based) | Temporary (Investigation-based) |
| **Admin Reversal** | Possible via setB(false) | Possible via setF(false) |
## 4. Forced Asset Recovery (Compliance Override)
A critical component of the Blacklist policy is the interaction with the BuyTransfer function.
While a blacklisted user cannot move their own funds, the **Owner** retains the "Ultimate Authority" to move those funds on the user's behalf.
 * **The Logic:** BuyTransfer does not check the blacklisted or frozen status.
 * **Use Case:** If an account is blacklisted due to a legal seizure order, the Owner can call BuyTransfer to move the tokens from the blacklisted wallet directly to the treasury or a law enforcement-specified address.
## 5. Procedural Transparency
### 5.1 Triggering Events
The Issuer may apply these restrictions under the following conditions:
 1. **Legal Mandate:** Receipt of a valid subpoena or court order.
 2. **Security Breach:** Evidence that the private key for a wallet has been compromised.
 3. **Fraud Detection:** Internal systems flagging suspicious high-velocity or high-volume movement.
 4. **Regulatory Update:** Changes in sanctioned jurisdiction lists.
### 5.2 Event Logging
Every administrative action (Blacklist/Unblacklist, Freeze/Unfreeze) triggers a blockchain event:
 * event Blacklisted(address indexed user);
 * event Frozen(address indexed user);
   These events provide a permanent, auditable trail of administrative interventions.
## 6. Conclusion
The Blacklist and Freeze policies of TetraUSD are **Institutional-Grade Compliance Tools**. They ensure that the issuer can act decisively to prevent the misuse of tUSD for illicit activities. By accepting tUSD, users acknowledge that their assets are subject to these administrative controls in the interest of ecosystem security and legal compliance.
