# Challenge 06: CrackMe (Storage Sleuth Edition)

Reverse engineer a deliberately leaky storage puzzle. The contract stashes a `bytes32` secret, leaks it one byte at a time, and expects a caller to provide both the first 16 bytes and a checksum that wraps an `unchecked` addition. Your goal is to reconstruct the key, compute the checksum, and flip the `solved` flag.

## 🎯 Objectives

- Inspect `CrackMe.sol` and identify the constraints enforced by `attempt(bytes16,uint64)`.
- Rebuild the 16-byte key via repeated calls to `revealByte(uint8)`.
- Craft the checksum so it satisfies the `unchecked` arithmetic branch.
- Automate the exploit with Solidity (`CrackMeSolution.sol`) and inline assembly (`CrackMeAssembly.sol`).

## 🧪 Local Testing

```bash
# Run all CrackMe unit tests (4/4 passing)
forge test --match-path "challenges/06-CrackMe/test/*.t.sol" -vv

# Focus on the reverse engineering helper tests
forge test --match-path "challenges/06-CrackMe/test/ReverseEngineering.t.sol" -vv

# Run the solution contract test
forge test --match-path "challenges/06-CrackMe/test/CrackMe.t.sol" -vv
```

**Current Status:** ✅ 4/4 tests passing
- ✅ `testRevertsWithBadKey()` – validates key constraints
- ✅ `testRevertsWithBadChecksum()` – validates checksum constraints  
- ✅ `testSolutionContractSolves()` – confirms high-level solver works
- ✅ `testRevealByteLeakesFullKey()` – confirms byte-leak mechanism

## 🚀 Deployment Script

A ready-to-broadcast script lives under `script/SolveCrackMe.s.sol`. Supply the target address and Forge will deploy the solver and flip the flag.

```bash
export CRACKME_TARGET=0xYourDeployedChallenge
forge script challenges/06-CrackMe/script/SolveCrackMe.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## 📚 Further Reading

- `SOLUTION_WALKTHROUGH.md` – step-by-step solver breakdown.
- `OVERFLOW_GUIDE.md` – refresher on `unchecked` arithmetic and deliberate wraparound traps.
