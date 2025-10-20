# Embedded Flag – CrackMe Challenge

The original Rinkeby challenge embedded a flag string that could be extracted via decompilation or bytecode analysis using XOR decoding.

## Original Extraction (Rinkeby)

From the bytecode decompiler at:  
`https://rinkeby.etherscan.io/bytecode-decompiler?a=0xDb2F21c03Efb692b65feE7c4B5D7614531DC45BE`

The memory layout contained:
```python
length = 26
mem = [0 for _ in range(length * 32)]
_40 = 0

mem[_40] = 51      # byte 0
mem[_40 + 32] = 64 # byte 1
# ... (24 more bytes)
mem[_40 + 800] = 68 # byte 25
```

Each byte was XOR'd with `112`:
```python
flag = ""
for idx in range(length):
    flag += chr(112 ^ mem[(32 * idx) + _40])
print(flag)
```

**Result:** `C0ngr@75_Y0u_CR@CK3D_m3854`

---

## Our Challenge

Our reconstructed CrackMe challenge (`src/contracts/CrackMe.sol`) takes a different approach:

1. **No embedded flag** in the bytecode—instead, the flag is conceptually "unlocked" when you solve the puzzle.
2. **Dynamic secret** passed at deployment: `bytes32 secret = keccak256("EVMCtfCrackMeSecret")`
3. **Storage leakage** via `revealByte(uint8)` – you reconstruct the key piece-by-piece.
4. **Proof of solution** – once solved, the `solved` flag and `solver` address are written to storage.

### How to Extract the "Flag" (Solution Success)

After calling `CrackMeSolution.solve()` or running the exploit:

```solidity
CrackMe puzzle = CrackMe(targetAddress);
require(puzzle.solved(), "Puzzle not solved");
address winner = puzzle.solver();
bytes32 secret = puzzle.rawSecret();
```

The "flag" is implicit in the state change: `solved = true` and `solver = <your_address>`.

---

## Teaching Value

Our challenge emphasizes:
- **Storage introspection** – leaking immutable state byte-by-byte
- **Memory layout** – packing/unpacking fixed-size types (bytes16, uint64)
- **Checksum validation** – deliberately wrapped in `unchecked` to teach overflow traps
- **On-chain proof** – no need for off-chain decompilation; the solution is verifiable in state

This is more realistic to modern EVM exploitation than static bytecode decompilation.
