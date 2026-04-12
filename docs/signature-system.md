# Signature System Specification (EIP-712)
This document details the meta-transaction capabilities of the **TetraUSD (tUSD)** contract. By implementing the **EIP-712** standard, tUSD allows for secure, off-chain message signing, enabling "gasless" transfers and delegated execution.
## 1. Technical Standard: EIP-712
TetraUSD utilizes EIP-712 to ensure that signed messages are bound to a specific contract and chain, preventing "replay attacks" where a signature intended for one network is used on another.
### 1.1 Domain Separator
The DOMAIN_SEPARATOR is uniquely generated during the contract deployment:
 * **Name:** "Tetra USD"
 * **Version:** "1"
 * **ChainID:** (Automatically captured at deployment)
 * **VerifyingContract:** The address of the tUSD deployment.
### 1.2 Type Hash
The contract defines a specific structured data format for execution:
```solidity
bytes32 public constant EXECUTE_TYPEHASH = keccak256(
    "Execute(address user,address to,uint256 amount,uint256 nonce,uint256 deadline)"
);

```
## 2. The execute Function Flow
The execute function allows a third party (the "Relayer") to submit a transaction on behalf of a user.
### 2.1 Process Sequence
 1. **Signing:** The user signs a message off-chain containing the destination, amount, a unique nonce, and a deadline.
 2. **Submission:** The Relayer calls the execute function, providing the parameters and the signature (v, r, s).
 3. **Verification:**
   * The contract reconstructs the hash and uses ecrecover to verify the signer's identity.
   * It checks if signer == user.
   * It verifies the deadline has not passed.
   * It verifies the nonce matches the user's current nonce in the contract.
 4. **Execution:** If valid, the contract increments the user's nonce and processes the transfer.
## 3. Security and Compliance Hooks
Even though execute is a meta-transaction, it is strictly governed by the same security policies as standard transfers.
### 3.1 "Satoshi Setting"
Inside the execute logic, the internal _beforeTransfer(user, to) hook is explicitly called. This means:
 * **Paused State:** If the contract is paused, signed executions will fail.
 * **Blacklist/Freeze:** If the signer or recipient is blacklisted/frozen, the signature cannot be executed.
 * **DEX Restriction:** Signatures cannot be used to bypass the pancakePair sell block.
## 4. Anti-Replay Mechanism (Nonces)
To prevent a single signature from being executed multiple times (Double-Spending), the contract tracks a mapping(address => uint256) public nonces.
 * Every successful execute call increments the user's nonce by 1.
 * A signature is only valid if it includes the **exact** current nonce of the user.
## 5. Risk Analysis
### 5.1 Signature Malleability
The contract uses the standard OpenZeppelin-style ecrecover pattern. While robust, users must ensure they are interacting with trusted front-end interfaces to sign messages, as a signature grants full permission for the specified amount.
### 5.2 Phishing Risk
Users may be tricked into signing an EIP-712 message that they believe is a simple login but is actually a tUSD.execute call.
 * **Mitigation:** The EIP-712 format displays the contract name and chain ID in the wallet (e.g., MetaMask), allowing users to verify the intent of the signature.
## 6. Conclusion
The signature system in TetraUSD provides an institutional-grade user experience by removing the requirement for users to hold native BNB for gas fees. By maintaining strict adherence to the _beforeTransfer security hooks, the protocol ensures that gasless convenience never compromises administrative control or compliance.
