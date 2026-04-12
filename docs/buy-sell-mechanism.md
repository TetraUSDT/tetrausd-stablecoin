# Buy and Sell Mechanisms (Liquidity Flow)
This document describes the technical implementation of the issuance (Buy) and redemption (Sell) processes for **TetraUSD (tUSD)**. The system supports two primary collateral types: **USDT** (BEP-20) and **BNB** (Native).
## 1. USDT-Based Operations (1:1 Peg)
The USDT mechanism is designed for high-stability issuance. It assumes a fixed 1:1 ratio between USDT and tUSD, maintaining a 6-decimal precision for both assets.
### 1.1 Purchasing with USDT (buyWithUSDT)
When a user calls buyWithUSDT, the following sequence occurs:
 1. **Transfer:** The contract executes transferFrom to move USDT from the user's wallet.
 2. **Redirection:** Instead of staying in the contract, the USDT is immediately sent to the treasury address.
 3. **Issuance:** The contract increments totalSupply and credits the user's balanceOf.
> **Security Note:** The treasury address is managed off-chain, allowing the operator to move collateral to cold storage or interest-bearing institutional accounts.
> 
### 1.2 Redemption for USDT (sellForUSDT)
Users can redeem their tUSD for USDT through the contract, provided the contract holds a USDT balance.
 * **Logic:** The contract burns the user's tUSD and transfers an equivalent amount of USDT from the contract's balance to the user.
 * **Dependency:** This function requires the Owner to periodically fund the contract with USDT, as incoming USDT from buys is redirected to the treasury.
## 2. BNB-Based Operations (Oracle-Dependent)
The BNB mechanism allows for the conversion of native chain assets into tUSD based on real-time market data.
### 2.1 Purchasing with BNB (buyWithBNB)
This is a payable function that calculates the tUSD output using the Chainlink Price Feed (BNB/USD).
 * **Price Discovery:** The contract calls _getBNBPrice() to retrieve the current exchange rate.
 * **Formula:**
   
 * **Execution:** The received BNB remains in the contract's balance (unless swept by the owner).
### 2.2 Redemption for BNB (sellForBNB)
Users can exit the tUSD ecosystem by requesting native BNB.
 * **Calculation:** The amount of BNB returned is calculated by dividing the token amount by the current oracle price.
 * **Constraint:** If address(this).balance is less than the calculated bnbAmount, the transaction will revert with "No liquidity".
## 3. Oracle Integration Details
TetraUSD utilizes the **Chainlink AggregatorV3Interface** for reliable price data.
 * **Oracle Address (Mainnet):** 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
 * **Update Frequency:** Dependent on Chainlink's heartbeat and price deviation parameters on the BNB Smart Chain.
 * **Risk:** In the event of an oracle failure or extreme market volatility (flash crashes), the buyWithBNB and sellForBNB functions may produce unfavorable rates.
## 4. Summary of Liquidity Constraints
Unlike decentralized AMMs (Automated Market Makers), the TetraUSD buy/sell mechanism is a **Direct-to-Contract** model.
| Feature | USDT Path | BNB Path |
|---|---|---|
| **Collateral Location** | Forwarded to Treasury | Held in Contract |
| **Price Stability** | Hardcoded 1:1 | Oracle-based (Variable) |
| **Redemption Risk** | Subject to Treasury Funding | Subject to Contract Balance |
| **Slippage** | 0% | 0% (at the moment of execution) |
## 5. Risk Disclosure: Liquidity Availability
Institutional users must be aware that the contract does not guarantee immediate liquidity for large-scale redemptions.
 1. **Treasury Dependency:** Since buyWithUSDT moves funds out of the contract, the sellForUSDT function only works if the Owner manually deposits USDT back into the contract.
 2. **Owner Sweep:** The Owner has the power via DepositNative and DepositToken to withdraw all collateral at any time, which would disable the sell functions for all users.
## 6. Conclusion
The Buy/Sell mechanism of TetraUSD is optimized for controlled issuance. It provides users with clear entry points while ensuring the administrative entity maintains full control over the underlying collateral via the treasury redirection and sweeping functions.
