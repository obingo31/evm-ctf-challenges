# Challenge 05: Casino

**Difficulty:** ⭐⭐ Beginner-Friendly  
**Vulnerability Type:** Predictable RNG / Block Number Entropy  
**Key Learning:** Never derive on-chain randomness from block metadata alone

---

## 📖 Overview

This level re-creates a classic "guess the number" casino that relies on `block.number` to generate randomness. Because block metadata is public and deterministic within a transaction, anyone can compute the same value as the contract and guarantee a win.

---

## 🎯 Objective

Win the game twice in a row so that `consecutiveWins > 1` and `done()` returns an empty array. Doing so demonstrates how useless block numbers and static seeds are as sources of randomness.

---

## 🔍 Vulnerability Analysis

```solidity
uint256 num = uint256(keccak256(abi.encodePacked(seed, block.number))) ^ 0x539;
```

- `seed` is a constant (`keccak256("satoshi nakmoto")`) and even exposed through `getSeed()`.
- `block.number` is **public state** – visible to everyone before they send a transaction.
- The XOR with `0x539` is deterministic, so the entire "random" output is predictable.

Within a single transaction the block number does not change, so an attacker can call `bet()` twice in a row using the same guessed value to set `consecutiveWins` to 2.

---

## 💥 Exploit Strategy

1. Compute the expected number off-chain or inside an attacker contract:

   ```solidity
   bytes32 seed = casino.getSeed();
   uint256 predicted = uint256(keccak256(abi.encodePacked(seed, block.number))) ^ 0x539;
   ```

2. Submit the same `predicted` value twice during the same block.
3. Observe `consecutiveWins[msg.sender]` increment to 2 and `done()` returning an empty array.

See `CasinoExploit.sol` for a high-level helper and `CasinoAssemblyAttack.sol` for a low-level assembly variant that hand-crafts calls and performs the XOR in Yul.

---

## 🧪 Testing

```bash
# Run unit tests for the challenge
make test-casino

# Verbose run with traces
make test-casino-verbose

# Fuzzing with Echidna (expect failure of the "secure" invariant)
make echidna-casino
```

The Echidna harness (`CasinoEchidna.sol`) encodes the property a *secure* casino should satisfy – "you cannot win twice in a row" – which immediately fails, demonstrating the predictability of the RNG.

---

## 🛡️ Mitigation

- Use a trusted randomness source such as Chainlink VRF or other verifiable randomness beacons.
- If randomness must be derived on-chain, combine block metadata with user-provided commits and reveals so the miner cannot manipulate the final result alone.
- Crucially, never rely on `block.timestamp`, `block.number`, or `blockhash` of recent blocks for critical randomness.

---

**Takeaway:** On-chain randomness is hard. Anything public and deterministic can be predicted by your adversaries.
