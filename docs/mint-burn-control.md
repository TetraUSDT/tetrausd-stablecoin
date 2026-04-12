# TetraUSD — Mint & Burn Control Model

## 1. Introduction

The TetraUSD (tUSD) mint and burn system is designed as a controlled issuance and redemption framework, allowing the protocol to manage supply dynamically while maintaining administrative oversight.

Unlike decentralized algorithmic systems, TetraUSD employs a centralized control model where minting and burning actions are governed by authorized roles and predefined mechanisms.

---

## 2. Supply Philosophy

TetraUSD operates under a flexible supply model:

- Total supply is not fixed
- Tokens can be minted on demand
- Tokens can be burned to reduce supply
- Supply changes depend on demand, treasury flow, and admin control

---

## 3. Minting Mechanisms

### Direct Minting
Authorized minters or owner can mint tokens.

### Batch Minting
Multiple addresses can receive tokens in a single transaction.

### USDT-Based Minting
1:1 mint ratio using USDT deposits.

### BNB-Based Minting
Dynamic minting using oracle price.

### ServerMint
Adds balance without increasing total supply (high risk).

---

## 4. Burning Mechanisms

### Direct Burn
Owner can burn tokens from any address.

### Batch Burn
Multiple address burn in one transaction.

### USDT Redemption
Burn tokens → receive USDT.

### BNB Redemption
Burn tokens → receive BNB.

---

## 5. Risks

- Centralized control risk
- Supply inconsistency risk
- Liquidity dependency risk
- Oracle dependency risk

---

## 6. Conclusion

TetraUSD mint/burn model is flexible but requires transparency and trust.
