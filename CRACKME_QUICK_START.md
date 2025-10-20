# EVM CTF Challenges – CrackMe Summary

## Overview

The **CrackMe** challenge teaches storage introspection and key reconstruction via intentional byte-by-byte leakage.

## Quick Start

```bash
# Run all CrackMe tests
make test-crackme

# Run specific test suites
make test-crackme-solution           # High-level solver
make test-crackme-reverse-engineering # Byte-leak mechanism

# Verbose output
make test-crackme-verbose
```

## Challenge Details

| Item | Value |
|------|-------|
| **Difficulty** | Medium |
| **Concepts** | Storage leakage, memory layout, checksum validation, overflow traps |
| **Language** | Solidity 0.8.18 |
| **Test Status** | ✅ 4/4 passing |

## What You'll Learn

1. **Storage Introspection** – Extract immutable state via exposed view functions
2. **Memory Layout** – Pack and unpack fixed-size types (bytes16, uint64)
3. **Checksum Validation** – Implement and bypass deliberate overflow checks
4. **On-Chain Proof** – Verify exploits through state changes, not bytecode decompilation

## Files

- `src/contracts/CrackMe.sol` – Challenge contract (immutable secret, byte leakage)
- `src/contracts/CrackMeSolution.sol` – High-level Solidity solver
- `src/contracts/CrackMeAssembly.sol` – Assembly-based solver (educational)
- `test/CrackMe.t.sol` – Unit tests
- `test/ReverseEngineering.t.sol` – Byte-leak validation tests
- `script/SolveCrackMe.s.sol` – Broadcast-ready exploit script
- `README.md` – Full challenge documentation
- `SOLUTION_WALKTHROUGH.md` – Step-by-step exploitation guide
- `OVERFLOW_GUIDE.md` – `unchecked` arithmetic reference
- `EMBEDDED_FLAG.md` – Flag extraction methodology

## Test Results

```
✅ testRevertsWithBadKey() – validates key constraints
✅ testRevertsWithBadChecksum() – validates checksum constraints
✅ testSolutionContractSolves() – confirms high-level solver works
✅ testRevealByteLeakesFullKey() – confirms byte-leak mechanism
```

## Next Steps

- Deploy to a testnet and solve live
- Extend the assembly solver to handle return value propagation
- Experiment with different checksum algorithms
- Add Echidna harness for fuzzing the storage layout

---

**Status:** Ready for deployment and testing ✅
