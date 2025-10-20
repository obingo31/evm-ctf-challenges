# Challenge 01: Reentrancy Attack

## 🎯 Challenge Goal

Steal all the Ether from the Reentrance contract.

## 📋 Difficulty

⭐⭐⭐ Intermediate

## 🔍 Vulnerability Overview

The **Reentrancy Attack** is one of the most famous vulnerabilities in Ethereum history, responsible for the DAO hack in 2016 where ~$60M was stolen.

### What is Reentrancy?

Reentrancy occurs when a contract makes an external call to another contract before updating its own state. The called contract can then call back into the original contract, exploiting the outdated state.

## 📝 Vulnerable Contract

```solidity
function withdraw(uint256 _amount) public {
    if (balances[msg.sender] >= _amount) {
        (bool result,) = msg.sender.call{value: _amount}("");  // ❌ External call first
        if (result) {
            _amount;
        }
        balances[msg.sender] -= _amount;  // ❌ State update after
    }
}
```

### The Bug

1. **Check**: Verifies balance is sufficient
2. **Interaction**: Sends ETH (external call)
3. **Effect**: Updates balance

This violates the **Checks-Effects-Interactions (CEI)** pattern!

## 💡 Attack Strategy

```
1. Donate 1 ETH → balances[attacker] = 1 ETH
2. Call withdraw(1 ETH)
   ├─> Check: balances[attacker] >= 1 ETH ✓
   ├─> Send 1 ETH to attacker
   │   └─> Triggers attacker's receive()
   │       └─> Call withdraw(1 ETH) again! (balance not updated yet)
   │           ├─> Check: balances[attacker] >= 1 ETH ✓ (still!)
   │           ├─> Send 1 ETH again
   │           └─> ... repeat until drained
   └─> Finally update: balances[attacker] -= 1 ETH
```

## 🔬 EVM Assembly Deep Dive

### Function Selector Calculation

```solidity
// Method 1: Pre-calculated (efficient)
mstore(0x00, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)

// Method 2: Dynamic (educational)
mstore(ptr, "withdraw(uint256)")
let hash := keccak256(ptr, 17)
let selector := shr(224, hash)
```

### Making the Call

```solidity
assembly {
    // Prepare calldata
    mstore(0x00, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
    mstore(0x04, amount)
    
    // Execute call
    let success := call(
        gas(),      // Forward all gas
        target,     // Target contract
        0,          // No ETH sent
        0x00,       // Input starts at memory 0
        0x24,       // Input size: 4 bytes selector + 32 bytes param
        0x00,       // Output location
        0x00        // Output size
    )
}
```

### Key Opcodes Used

| Opcode | Description | Gas Cost |
|--------|-------------|----------|
| `sload(slot)` | Load from storage | 2100/100 |
| `sstore(slot, val)` | Store to storage | 20000/5000 |
| `balance(addr)` | Get ETH balance | 700 |
| `call(...)` | External call | 700+ |
| `caller()` | Get msg.sender | 2 |
| `keccak256(offset, len)` | Hash data | 30 + 6/word |

## 🛡️ The Fix

```solidity
function withdraw(uint256 _amount) public {
    // CHECK
    require(balances[msg.sender] >= _amount, "Insufficient balance");
    
    // EFFECT - Update state FIRST
    balances[msg.sender] -= _amount;
    
    // INTERACTION - External call LAST
    (bool result,) = msg.sender.call{value: _amount}("");
    require(result, "Transfer failed");
}
```

### Alternative: ReentrancyGuard

```solidity
uint256 private locked = 1;

modifier nonReentrant() {
    require(locked == 1, "Reentrant call");
    locked = 2;
    _;
    locked = 1;
}

function withdraw(uint256 _amount) public nonReentrant {
    // Safe now
}
```

## 🧪 Running the Challenge

```bash
# Run tests
forge test --match-path challenges/01-Reentrancy/test/*.t.sol -vvvv

# With gas report
forge test --match-path challenges/01-Reentrancy/test/*.t.sol --gas-report

# With traces
forge test --match-test testReentrancyExploit -vvvvv
```

## 📊 Expected Output

```
Running 4 tests for challenges/01-Reentrancy/test/Reentrance.t.sol:ReentranceTest
[PASS] testDonation() (gas: 50234)
[PASS] testExploit() (gas: 123456)
[PASS] testReentrancyExploit() (gas: 145678)
[PASS] testTargetDrained() (gas: 156789)

Test result: ok. 4 passed; 0 failed
```

## 🎓 Learning Objectives

After completing this challenge, you should understand:

- ✅ How reentrancy attacks work
- ✅ The Checks-Effects-Interactions pattern
- ✅ EVM assembly for external calls
- ✅ Function selector encoding
- ✅ Memory and storage operations
- ✅ Gas optimization techniques

## 📚 Further Reading

- [Consensys: Reentrancy After Istanbul](https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/)
- [The DAO Hack Explained](https://www.coindesk.com/learn/2016/06/25/understanding-the-dao-attack/)
- [EIP-1884: Repricing for trie-size-dependent opcodes](https://eips.ethereum.org/EIPS/eip-1884)

## 🏆 Challenge Complete!

Ready for the next challenge? Check out [Challenge 02: Fallback](../02-Fallback/)

---

💡 **Pro Tip**: Always follow CEI pattern and use OpenZeppelin's ReentrancyGuard in production!