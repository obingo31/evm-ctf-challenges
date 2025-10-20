# EVM Opcodes Reference

Complete reference guide for EVM opcodes used in inline assembly.

## 📚 Table of Contents

- [Stack Operations](#stack-operations)
- [Memory Operations](#memory-operations)
- [Storage Operations](#storage-operations)
- [Control Flow](#control-flow)
- [Arithmetic Operations](#arithmetic-operations)
- [Comparison Operations](#comparison-operations)
- [Bitwise Operations](#bitwise-operations)
- [Environmental Information](#environmental-information)
- [Block Information](#block-information)
- [Cryptographic Operations](#cryptographic-operations)

## Stack Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `pop` | 2 | Remove top item | `pop(x)` |
| `dup1-dup16` | 3 | Duplicate Nth item | `dup1(x)` |
| `swap1-swap16` | 3 | Swap top with Nth | `swap1(x, y)` |

## Memory Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `mload(offset)` | 3 | Load word from memory | `let x := mload(0x40)` |
| `mstore(offset, val)` | 3 | Store word to memory | `mstore(0x00, 0x1234)` |
| `mstore8(offset, val)` | 3 | Store byte to memory | `mstore8(0x00, 0xFF)` |
| `msize()` | 2 | Get memory size | `let size := msize()` |

### Memory Layout

```
0x00-0x3F: Scratch space (64 bytes)
0x40-0x5F: Free memory pointer (32 bytes)
0x60-0x7F: Zero slot (32 bytes)
0x80+: Free memory
```

## Storage Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `sload(slot)` | 2100/100 | Load from storage | `let x := sload(0)` |
| `sstore(slot, val)` | 20000/5000 | Store to storage | `sstore(0, 0x1234)` |

### Gas Costs
- **Cold access**: First access costs more (2100 for `sload`, 20000 for `sstore`)
- **Warm access**: Subsequent accesses cheaper (100 for `sload`, 5000/100 for `sstore`)
- **Zero to non-zero**: 20000 gas
- **Non-zero to zero**: 5000 gas + refund

## Control Flow

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `stop()` | 0 | Stop execution | `stop()` |
| `return(offset, len)` | 0 | Return data | `return(0x00, 0x20)` |
| `revert(offset, len)` | 0 | Revert with data | `revert(0x00, 0x20)` |
| `invalid()` | All | Invalid opcode | `invalid()` |

### Conditionals

```solidity
if condition {
    // true branch
}

// Equivalent to:
switch condition
case 0 { /* false */ }
default { /* true */ }
```

## Arithmetic Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `add(x, y)` | 3 | Addition | `let z := add(x, y)` |
| `sub(x, y)` | 3 | Subtraction | `let z := sub(x, y)` |
| `mul(x, y)` | 5 | Multiplication | `let z := mul(x, y)` |
| `div(x, y)` | 5 | Division | `let z := div(x, y)` |
| `sdiv(x, y)` | 5 | Signed division | `let z := sdiv(x, y)` |
| `mod(x, y)` | 5 | Modulo | `let z := mod(x, y)` |
| `smod(x, y)` | 5 | Signed modulo | `let z := smod(x, y)` |
| `exp(x, y)` | 10 | Exponentiation | `let z := exp(x, y)` |
| `addmod(x, y, m)` | 8 | (x + y) % m | `let z := addmod(x, y, m)` |
| `mulmod(x, y, m)` | 8 | (x * y) % m | `let z := mulmod(x, y, m)` |

## Comparison Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `lt(x, y)` | 3 | Less than | `if lt(x, y) {}` |
| `gt(x, y)` | 3 | Greater than | `if gt(x, y) {}` |
| `slt(x, y)` | 3 | Signed less than | `if slt(x, y) {}` |
| `sgt(x, y)` | 3 | Signed greater than | `if sgt(x, y) {}` |
| `eq(x, y)` | 3 | Equal | `if eq(x, y) {}` |
| `iszero(x)` | 3 | Is zero | `if iszero(x) {}` |

## Bitwise Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `and(x, y)` | 3 | Bitwise AND | `let z := and(x, y)` |
| `or(x, y)` | 3 | Bitwise OR | `let z := or(x, y)` |
| `xor(x, y)` | 3 | Bitwise XOR | `let z := xor(x, y)` |
| `not(x)` | 3 | Bitwise NOT | `let z := not(x)` |
| `shl(bits, val)` | 3 | Shift left | `let z := shl(8, x)` |
| `shr(bits, val)` | 3 | Shift right | `let z := shr(8, x)` |
| `sar(bits, val)` | 3 | Arithmetic shift right | `let z := sar(8, x)` |
| `byte(n, x)` | 3 | Get byte at position | `let z := byte(0, x)` |

## Environmental Information

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `address()` | 2 | Current contract address | `let addr := address()` |
| `balance(addr)` | 700 | Get ETH balance | `let bal := balance(addr)` |
| `selfbalance()` | 5 | Current contract balance | `let bal := selfbalance()` |
| `caller()` | 2 | msg.sender | `let sender := caller()` |
| `callvalue()` | 2 | msg.value | `let value := callvalue()` |
| `calldataload(offset)` | 3 | Load calldata | `let data := calldataload(0)` |
| `calldatasize()` | 2 | Calldata size | `let size := calldatasize()` |
| `calldatacopy(t, f, s)` | 3 | Copy calldata | `calldatacopy(0, 0, calldatasize())` |
| `codesize()` | 2 | Code size | `let size := codesize()` |
| `codecopy(t, f, s)` | 3 | Copy code | `codecopy(0, 0, codesize())` |
| `extcodesize(addr)` | 700 | External code size | `let size := extcodesize(addr)` |
| `extcodecopy(a, t, f, s)` | 700 | Copy external code | `extcodecopy(addr, 0, 0, size)` |
| `extcodehash(addr)` | 700 | External code hash | `let hash := extcodehash(addr)` |
| `returndatasize()` | 2 | Return data size | `let size := returndatasize()` |
| `returndatacopy(t, f, s)` | 3 | Copy return data | `returndatacopy(0, 0, size)` |

## Block Information

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `blockhash(n)` | 20 | Block hash | `let hash := blockhash(sub(number(), 1))` |
| `coinbase()` | 2 | Block miner | `let miner := coinbase()` |
| `timestamp()` | 2 | Block timestamp | `let time := timestamp()` |
| `number()` | 2 | Block number | `let num := number()` |
| `difficulty()` | 2 | Block difficulty | `let diff := difficulty()` |
| `gaslimit()` | 2 | Block gas limit | `let limit := gaslimit()` |
| `chainid()` | 2 | Chain ID | `let id := chainid()` |
| `basefee()` | 2 | Base fee | `let fee := basefee()` |

## Cryptographic Operations

| Opcode | Gas | Description | Example |
|--------|-----|-------------|---------|
| `keccak256(offset, len)` | 30 + 6/word | Keccak-256 hash | `let hash := keccak256(0, 32)` |

### Function Selector Calculation

```solidity
// Calculate function selector
mstore(0x00, "transfer(address,uint256)")
let hash := keccak256(0x00, 25)
let selector := shr(224, hash) // First 4 bytes
```

## External Calls

### CALL

```solidity
call(gas, addr, value, argsOffset, argsSize, retOffset, retSize) → success
```

Example:
```solidity
let success := call(
    gas(),                  // Forward all gas
    targetAddress,          // Address to call
    0,                      // ETH to send
    0x00,                   // Input data offset
    0x24,                   // Input data size
    0x00,                   // Output data offset
    0x00                    // Output data size
)
```

### STATICCALL

```solidity
staticcall(gas, addr, argsOffset, argsSize, retOffset, retSize) → success
```

Same as `call` but without value transfer (read-only).

### DELEGATECALL

```solidity
delegatecall(gas, addr, argsOffset, argsSize, retOffset, retSize) → success
```

Executes code in the context of the current contract.

### Gas Costs

| Operation | Base Cost | Additional |
|-----------|-----------|------------|
| `call` | 700 | + value transfer |
| `staticcall` | 700 | - |
| `delegatecall` | 700 | - |
| Value transfer | 9000 | - |
| New account | 25000 | if recipient doesn't exist |

## Best Practices

### 1. Use Free Memory Pointer

```solidity
let ptr := mload(0x40)  // Get free memory pointer
mstore(ptr, data)       // Write data
mstore(0x40, add(ptr, 0x20))  // Update pointer
```

### 2. Efficient Storage Access

```solidity
// Cache storage reads
let x := sload(slot)
// Use x multiple times instead of multiple sloads
```

### 3. Optimize Gas

```solidity
// Use selfbalance() instead of balance(address())
let bal := selfbalance()  // 5 gas vs 700 gas

// Use iszero instead of eq(x, 0)
if iszero(x) {}  // More readable

// Combine operations
let result := and(shr(224, hash), 0xFFFFFFFF)
```

### 4. Safe Math

```solidity
// Check for overflow
let result := add(x, y)
if lt(result, x) {
    revert(0, 0)  // Overflow detected
}
```

## Common Patterns

### Extract Function Selector from Calldata

```solidity
let selector := shr(224, calldataload(0))
```

### Encode Function Call

```solidity
mstore(0x00, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // transfer(address,uint256)
mstore(0x04, to)
mstore(0x24, amount)
```

### Return Dynamic Data

```solidity
let size := mload(data)
return(data, add(size, 0x20))
```

### Revert with String

```solidity
let ptr := mload(0x40)
mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Error(string)
mstore(add(ptr, 0x04), 0x20)
mstore(add(ptr, 0x24), 5)
mstore(add(ptr, 0x44), "Error")
revert(ptr, 0x64)
```

---

## Further Resources

- [EVM Codes](https://www.evm.codes/) - Interactive opcode reference
- [Solidity Assembly Documentation](https://docs.soliditylang.org/en/latest/assembly.html)
- [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf)

Happy hacking! 🚀
