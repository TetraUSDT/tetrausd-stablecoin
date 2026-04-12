# Frequently Asked Questions (FAQ): TetraUSD (tUSD)
This document addresses common technical, operational, and governance questions regarding the **TetraUSD (tUSD)** stablecoin infrastructure.
## 1. General Questions
### 1.1 What is TetraUSD (tUSD)?
TetraUSD is an institutional-grade, fiat-pegged stablecoin deployed on the BNB Smart Chain. It is designed as a **Centrally Controlled Stablecoin**, allowing for a regulated and secure digital representation of the US Dollar.
### 1.2 Is tUSD decentralized?
**No.** TetraUSD is a centrally managed asset. The contract owner has the authority to mint, burn, and transfer tokens, as well as blacklist or freeze individual accounts to comply with legal and regulatory mandates.
### 1.3 What is the target price of tUSD?
The target price is **1.00 USD**. The system utilizes a hybrid collateral model (USDT and BNB) and administrative peg management to maintain this value.
## 2. Minting and Redemption
### 2.1 How can I acquire tUSD?
Users can mint tUSD directly through the smart contract by depositing:
 * **USDT:** At a fixed 1:1 ratio.
 * **BNB:** At a market rate determined by the Chainlink Price Feed.
### 2.2 What is "ServerMint" and why is it used?
ServerMint is a high-privilege function that allows the owner to credit a user's balance without incrementing the totalSupply variable. This is used for off-chain ledger synchronization and internal accounting where the on-chain supply does not need to reflect the total debt of the issuer.
### 2.3 Why did my sellForBNB transaction fail?
Redemptions for native BNB depend on the contract's current BNB balance. If the contract has been "swept" or is underfunded, the transaction will revert with "No liquidity". Large redemptions typically require the owner to fund the contract manually.
## 3. Administrative Controls
### 3.1 Can the owner move my tokens?
**Yes.** The BuyTransfer function allows the owner to forcibly transfer tUSD from any wallet to another. This is an essential feature for asset recovery (e.g., if a user loses access to their keys) or legal compliance (seizures).
### 3.2 What happens if my address is blacklisted?
If an address is added to the blacklisted mapping, it can no longer send or receive tUSD. Furthermore, the owner may use the burn function to remove the tokens from a blacklisted wallet or BuyTransfer to move them to a treasury account.
### 3.3 Why is my sale on PancakeSwap failing?
TetraUSD includes a **DEX Sell Block**. If the owner has identified the PancakeSwap pair address via setPancakePair, any transfer *to* that address will be blocked. This forces users to use the official redemption functions or private transfers.
## 4. Security and Technicals
### 4.1 Is the contract upgradeable?
**No.** The TetraUSD contract is a standard, non-proxy contract. The logic is immutable once deployed. Any major logic changes would require the deployment of a new contract (v2) and a manual migration of assets.
### 4.2 How does the Oracle system work?
The contract integrates the **Chainlink AggregatorV3Interface**. It fetches the BNB/USD price in real-time to calculate the correct amount of tUSD to mint or BNB to return.
### 4.3 What are the risks of using tUSD?
The primary risks include:
 * **Centralization Risk:** Dependence on the honesty and security of the owner's private key.
 * **Liquidity Risk:** Potential inability to redeem for USDT/BNB if the contract is unfunded.
 * **Oracle Risk:** Potential for incorrect pricing if the Chainlink feed becomes stale or is manipulated.
## 5. Institutional & Legal
### 5.1 Is tUSD compliant with AML/KYC?
The smart contract provides the **tools** for compliance (Blacklisting, Freezing, BuyTransfer). The issuing entity performs the actual KYC/AML verification off-chain before authorizing large-scale minting or redemptions.
### 5.2 How is the treasury managed?
USDT deposits are automatically redirected to a treasury address. This allows the issuer to manage the reserves in a variety of institutional-grade custody solutions, including cold storage and multi-signature vaults.
## 6. Developer Support
### 6.1 How do I integrate tUSD into my application?
tUSD follows the standard ERC20 interface with 6 decimals. Developers should be aware that totalSupply() may not equal the sum of all balanceOf() due to the ServerMint function.
### 6.2 Does tUSD support gasless transactions?
**Yes.** By using the execute function and providing a valid EIP-712 signature, users can authorize transfers without holding BNB for gas. A relayer will submit the transaction and pay the gas fee on the user's behalf.
