# Challenge 06: CrackMe – Complete Status ✅

## Overview

Challenge 06 is a **storage introspection** puzzle where the goal is to:
1. **Reconstruct a 16-byte key** by calling `revealByte(uint8)` 16 times
2. **Compute a checksum** using wrapped arithmetic: `uint64(address(solver)) + 1`
3. **Call `attempt(bytes16, uint64)`** to flip the `solved` flag and prove exploitation

## Test Status

| Test | Status | Details |
|------|--------|---------|
| `testRevertsWithBadKey()` | ✅ PASS | Rejects incorrect key |
| `testRevertsWithBadChecksum()` | ✅ PASS | Rejects incorrect checksum |
| `testSolutionContractSolves()` | ✅ PASS | High-level solver works |
| `testRevealByteLeakesFullKey()` | ✅ PASS | Byte leakage confirmed |

**Total: 4/4 Passing**

## Makefile Targets

```bash
# Main test targets
make test-crackme                    # Run all CrackMe tests
make test-crackme-verbose            # Verbose output
make test-crackme-solution           # Test solver specifically
make test-crackme-reverse-engineering # Test byte-leak mechanism
```

## File Structure

```
challenges/06-CrackMe/
├── src/
│   └── contracts/
│       ├── CrackMe.sol              # Challenge (immutable, leaks bytes)
│       ├── CrackMeSolution.sol      # High-level solver ✅ WORKS
│       └── CrackMeAssembly.sol      # Assembly solver (educational)
├── test/
│   ├── CrackMe.t.sol                # Main test suite
│   └── ReverseEngineering.t.sol     # Byte-leak validation
├── script/
│   └── SolveCrackMe.s.sol           # Broadcast-ready script
├── docs/
│   ├── README.md                    # Full challenge guide
│   ├── SOLUTION_WALKTHROUGH.md      # Exploitation steps
│   ├── OVERFLOW_GUIDE.md            # Unchecked arithmetic reference
│   └── EMBEDDED_FLAG.md             # Flag extraction methodology
└── foundry.toml                     # Foundry config
```

## Key Learning Points

### 1. **Storage Leakage via View Functions**
The challenge intentionally exposes a byte at a time through `revealByte()`:
```solidity
function revealByte(uint8 index) external view returns (bytes1 b) {
    require(index < 16, "index out of range");
    bytes memory encoded = abi.encodePacked(bytes16(secret));
    return encoded[index];
}
```

### 2. **Memory Layout & Packing**
- `bytes16` fits in 16 bytes (lower half of a 256-bit word)
- `uint64` fits in 8 bytes (rightmost 8 bytes when ABI-encoded)
- Solvers must correctly pack both into a single `attempt()` call

### 3. **Checksum with Overflow Trap**
```solidity
unchecked {
    nonce += 1;
}
uint64 expected = uint64(uint160(msg.sender)) + nonce;
```
The `unchecked` block allows silent wraparound—future calls can bypass the check if `nonce` overflows.

### 4. **High-Level vs. Assembly**
- **CrackMeSolution.sol**: Uses Solidity helpers (`abi.encodeWithSelector`) – simple, works
- **CrackMeAssembly.sol**: Raw assembly for calldata crafting – educational but complex Yul scoping issues

## Quick Walkthrough

1. **Deploy** `CrackMe` with a secret
2. **Discover** the byte-leak via `revealByte(0..15)`
3. **Reconstruct** 16 bytes into a `bytes16` key
4. **Compute** checksum = `uint64(address(solver)) + 1`
5. **Call** `attempt(key, checksum)`
6. **Verify** state: `solved == true`

## Next Challenge

When ready, move to **Challenge 07** (or continue with remaining challenges).

---

**Status:** ✅ Complete, tested, documented, and ready for deployment.
