# Mint and Burn Control Specification
This document outlines the issuance (Minting) and redemption/destruction (Burning) mechanisms of the **TetraUSD (tUSD)** stablecoin. The system supports both collateral-backed automated issuance and manual administrative overrides.
## 1. Issuance (Minting) Overview
TetraUSD employs three distinct minting pathways designed for different operational needs: **Automated Collateralized Minting**, **Standard Administrative Minting**, and **Internal Ledger Synchronization (ServerMint)**.
### 1.1 Automated Collateralized Minting
Users can trigger the minting process by depositing supported collateral (USDT or BNB).
| Function | Collateral | Rate | Logic |
|---|---|---|---|
| buyWithUSDT | USDT (ERC20) | 1:1 | Transfers USDT to treasury, mints tUSD to user. |
| buyWithBNB | Native BNB | Oracle Based | Fetches BNB/USD price via Chainlink, mints equivalent tUSD. |
**Technical Formula (BNB):**

### 1.2 Standard Administrative Minting (onlyMinter)
The owner or authorized minters can issue tokens without a direct on-chain collateral deposit. This is typically used for:
 * Off-chain wire transfer settlements.
 * Liquidity provisioning for partner exchanges.
 * Ecosystem rewards.
**Functions:**
 * mint(address to, uint256 amount): Issues tokens to a single recipient.
 * mintTransfer(address[] users, uint256[] amounts): Efficient batch minting for multiple recipients in a single transaction.
## 2. The ServerMint Mechanism (Critical)
The ServerMint function is a specialized administrative tool that allows the owner to credit a user's balance directly.
### 2.1 Technical Deviation
Unlike the standard mint function, ServerMint **does not increment the totalSupply variable**.
```solidity
function ServerMint(address to, uint256 amount) external onlyOwner {
    balanceOf[to] += amount;
    emit Transfer(address(0), to, amount);
}

```
### 2.2 Design Rationale
This function is intended for internal accounting synchronization where the circulating supply is managed or tracked by an external database/off-chain ledger.
### 2.3 Audit Implications
 * **Total Supply Inconsistency:** The sum of all balanceOf mappings will exceed the reported totalSupply.
 * **Transparency:** Third-party analytics tools (e.g., CoinMarketCap) that rely solely on totalSupply() will display lower-than-actual circulating supply data.
## 3. Destruction (Burning) Overview
The burning mechanism is strictly controlled by the owner to ensure total supply management and regulatory compliance.
### 3.1 Standard Burn
The owner can remove tokens from any address. This is not limited to the owner's own balance.
 * **Function:** burn(address from, uint256 amount)
 * **Constraint:** The target address must have a balance \ge the burn amount.
### 3.2 Batch Burn
To handle large-scale supply contractions or corrections, the burnTransfer function is utilized.
 * **Function:** burnTransfer(address[] users, uint256[] amounts)
## 4. Permission Matrix
| Function | Permission | Updates totalSupply | Updates balanceOf |
|---|---|---|---|
| buyWithUSDT | Public | Yes | Yes |
| buyWithBNB | Public | Yes | Yes |
| mint | Minter/Owner | Yes | Yes |
| ServerMint | Owner Only | **No** | **Yes** |
| burn | Owner Only | Yes | Yes |
## 5. Risk Analysis & Safeguards
### 5.1 Infinite Minting Risk
The owner and minter roles have the technical capability to mint an unlimited amount of tUSD. This is a **Centralization Risk**. Institutional users must trust the governance of the owner address.
### 5.2 "Ghost Supply" Risk
The usage of ServerMint creates tokens that are not visible in the global totalSupply.
 * **Mitigation:** Auditors must calculate the "Actual Supply" by summing all balances or monitoring Transfer events from the 0x00...00 address, rather than relying on the totalSupply variable.
### 5.3 Forced Destruction
Since the owner can burn tokens from any wallet, users do not have "absolute" ownership of their assets. This feature is architected for:
 1. **Sanctions Compliance:** Removing tokens from blacklisted entities.
 2. **Error Correction:** Reversing accidental issuances.
## 6. Conclusion
The Mint/Burn architecture of TetraUSD is optimized for **flexibility and control**. While it deviates from decentralized standards (especially via ServerMint), it provides the necessary tools for an institutionally managed stablecoin to maintain its peg and fulfill legal obligations.
