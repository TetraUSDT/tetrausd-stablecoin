# Oracle System Specification
This document details the integration of external price feeds into the **TetraUSD (tUSD)** smart contract. The oracle system is fundamental for calculating the exchange rate during BNB-based minting and redemption.
## 1. Core Integration: Chainlink Price Feeds
TetraUSD utilizes the industry-standard **Chainlink Decentralized Oracle Network (DON)** to obtain high-fidelity, real-time market data for the BNB/USD pair.
### 1.1 Technical Provider Details
 * **Provider:** Chainlink
 * **Interface:** AggregatorV3Interface
 * **Network:** Binance Smart Chain (BSC)
 * **Contract Address:** 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE (BNB/USD Aggregator)
## 2. Price Discovery Logic
The contract features an internal view function _getBNBPrice() which queries the Chainlink aggregator.
### 2.1 Data Retrieval
The function calls latestRoundData() and extracts the answer (the current price).
```solidity
function _getBNBPrice() internal view returns (uint256) {
    (, int256 price,,,) = priceFeed.latestRoundData();
    return uint256(price); // Returns price with 8 decimals
}

```
### 2.2 Normalization and Precision
 * **Chainlink Output:** The BNB/USD price is returned with **8 decimals** (e.g., 600.00 is represented as 60,000,000,000).
 * **tUSD Precision:** tUSD uses **6 decimals**.
 * **Scaling Factor:** During calculations in buyWithBNB and sellForBNB, the system uses a scaling factor of 1e20 to handle the transition between 18-decimal BNB (Wei) and 6-decimal tUSD, ensuring mathematical accuracy without rounding errors.
## 3. Usage in Economic Functions
The Oracle is the primary arbiter for two key functions:
### 3.1 Buying with BNB (buyWithBNB)
When a user sends native BNB, the contract calculates the tUSD to mint:

### 3.2 Selling for BNB (sellForBNB)
When a user redeems tUSD for native BNB:

## 4. Oracle Security and Fail-Safes
### 4.1 Transparency
The Oracle address is public and can be verified on BscScan. The priceFeed variable is immutable after deployment (it cannot be changed by the owner without a contract upgrade, providing a layer of trust).
### 4.2 Potential Risks
Despite Chainlink's robustness, the following risks are acknowledged:
 * **Stale Pricing:** If the Chainlink network fails to update the heartbeat of the BNB/USD feed, the contract may execute trades at outdated prices.
 * **Flash Loan Attacks:** While Chainlink is resistant to single-source manipulation, extreme volatility in external markets can affect the minting/burning rates.
 * **Network Latency:** There may be a slight discrepancy between the CEX (Centralized Exchange) price and the on-chain Oracle price due to block times.
## 5. Administrative Oversight
While the priceFeed address itself is set in the constructor, the **Owner** retains the power to:
 1. **Pause the Contract:** Using setP(true), the owner can halt all Oracle-dependent functions in the event of a known Oracle failure or "black swan" market event.
 2. **Liquidity Control:** The owner can withdraw the BNB balance from the contract if they believe the Oracle-based redemptions are putting the treasury at risk.
## 6. Conclusion
The Oracle system in TetraUSD is designed for **High Fidelity and Minimal Latency**. By outsourcing price discovery to Chainlink, the protocol avoids the vulnerabilities associated with centralized or internal price reporting, though it remains subject to the broader availability of the Chainlink network on BSC.
