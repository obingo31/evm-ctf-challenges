# Challenge 11: GasGrief - Gas Griefing & DoS Attacks

> **Learn to identify and prevent gas griefing attacks that can make contracts unusable**

## 🎯 Challenge Overview

**GasGrief** demonstrates sophisticated **gas griefing** and **Denial of Service (DoS)** attacks where malicious actors can make smart contracts unusable by exploiting unbounded gas consumption patterns.

### 🔍 Vulnerability Focus
- **Unbounded Loops**: Operations that scale with user-controlled input
- **Gas Consumption Attacks**: Deliberately consuming excessive gas
- **DoS via Block Gas Limit**: Making functions impossible to execute
- **Nested Loop Vulnerabilities**: Quadratic gas consumption patterns

## 💡 Educational Goals

1. **Understand Gas Economics**: Learn how gas limits protect the network
2. **Identify Vulnerability Patterns**: Recognize unbounded operations
3. **Implement Mitigations**: Add gas limits and pagination
4. **Design Gas-Efficient Systems**: Build sustainable smart contracts

## 🏗️ Contract Architecture

### Core Components

```solidity
contract GasGrief {
    // Vulnerable functions
    function addParticipants(address[] calldata newParticipants) external; // Unbounded loop
    function distributeRewards() external;                                  // Scales with participants
    function batchProcessOperations(...) external;                         // Nested loops
    function computeExpensiveFunction(uint256 iterations) external;        // User-controlled gas
    
    // Mitigation examples
    function addParticipantsOptimized(address[] calldata newParticipants) external;  // Gas limited
    function distributeRewardsPaginated(uint256 start, uint256 batch) external;      // Paginated
}
```

### State Variables
- **`participants[]`**: Dynamic array that grows unboundedly
- **`gasUsageByAddress`**: Tracks gas consumption per user  
- **`maxGasUsed`**: Records highest gas consumption
- **`distributionInProgress`**: Prevents reentrancy during operations

## ⚡ Attack Vectors

### 1. **Unbounded Loop Attack**
```solidity
// VULNERABLE: No limit on array size
function addParticipants(address[] calldata newParticipants) external {
    for (uint256 i = 0; i < newParticipants.length; i++) {  // Unbounded!
        participants.push(newParticipants[i]);
    }
}
```

**Attack**: Submit array with 10,000+ addresses → consume all block gas

### 2. **Distribution DoS Attack**
```solidity
// VULNERABLE: Gas consumption scales with participant count
function distributeRewards() external {
    for (uint256 i = 0; i < participants.length; i++) {     // Unbounded!
        balances[participants[i]] += reward;
    }
}
```

**Attack**: Add many participants → make distribution impossible

### 3. **Nested Loop Gas Griefing**
```solidity
// VULNERABLE: O(n²) gas consumption
function batchProcessOperations(...) external {
    for (uint256 i = 0; i < targets.length; i++) {          // N operations
        for (uint256 j = 0; j < participants.length; j++) { // M participants
            // O(N×M) gas consumption!
        }
    }
}
```

**Attack**: Large `targets` array + many participants = quadratic gas explosion

### 4. **User-Controlled Computation**
```solidity
// VULNERABLE: User controls iteration count
function computeExpensiveFunction(uint256 iterations) external {
    for (uint256 i = 0; i < iterations; i++) {              // User-controlled!
        result = expensiveOperation(result);
    }
}
```

**Attack**: Call with `iterations = 1,000,000` → consume all gas

## 🛡️ Mitigation Strategies

### 1. **Gas Limits**
```solidity
function addParticipantsOptimized(address[] calldata newParticipants) external {
    require(newParticipants.length <= 50, "Too many participants at once");
    
    for (uint256 i = 0; i < newParticipants.length; i++) {
        participants.push(newParticipants[i]);
        
        if (gasleft() < 20000) break; // Circuit breaker
    }
}
```

### 2. **Pagination**
```solidity
function distributeRewardsPaginated(uint256 startIndex, uint256 batchSize) external {
    require(batchSize <= 100, "Batch size too large");
    
    uint256 endIndex = startIndex + batchSize;
    if (endIndex > participants.length) {
        endIndex = participants.length;
    }
    
    for (uint256 i = startIndex; i < endIndex; i++) {
        balances[participants[i]] += reward;
    }
}
```

### 3. **Gas Monitoring**
```solidity
uint256 startGas = gasleft();
// ... perform operations ...
uint256 gasUsed = startGas - gasleft();

if (gasUsed > MAX_GAS_PER_USER) {
    revert("Gas limit exceeded");
}
```

### 4. **Circuit Breakers**
```solidity
modifier gasCheck() {
    uint256 startGas = gasleft();
    _;
    require(startGas - gasleft() < MAX_FUNCTION_GAS, "Function too expensive");
}
```

## 🧪 Testing Strategy

### Gas Griefing Tests
- **Large Array Attack**: Test with 1000+ participant arrays
- **Distribution DoS**: Verify distribution becomes impossible
- **Nested Loop Explosion**: Test quadratic gas consumption
- **Computation Attack**: User-controlled expensive operations

### Mitigation Tests  
- **Gas Limit Enforcement**: Verify limits are respected
- **Pagination Effectiveness**: Test batch processing works
- **Circuit Breaker Triggers**: Verify emergency stops work
- **Optimization Validation**: Confirm gas efficiency improvements

## 🎮 Challenge Modes

### Mode 1: **Gas Griefing Attack**
- Add 1000+ participants in single transaction
- Make `distributeRewards()` impossible to execute
- Demonstrate contract becomes unusable

### Mode 2: **Optimization Implementation** 
- Use `addParticipantsOptimized()` with proper limits
- Implement paginated distribution
- Maintain contract usability

### Mode 3: **DoS Prevention**
- Design gas-efficient alternatives
- Implement proper circuit breakers
- Build sustainable operations

## 📊 Gas Analysis

### Consumption Patterns
```
Normal operation:     ~50,000 gas
100 participants:     ~2,000,000 gas  
1000 participants:    ~20,000,000 gas (approaching block limit!)
10000 participants:   IMPOSSIBLE (exceeds block gas limit)
```

### Block Gas Limits
- **Ethereum Mainnet**: ~30,000,000 gas per block
- **Critical Threshold**: ~15,000,000 gas (50% of block)
- **Safe Operations**: <1,000,000 gas per function call

## 🚀 Getting Started

### 1. **Build & Test**
```bash
cd challenges/11-GasGrief
forge build
forge test -vv
```

### 2. **Run Gas Analysis**
```bash
forge test --gas-report
```

### 3. **Deploy & Attack**
```bash
export YOUR_PRIVATE_KEY="0x..."
./deploy_direct.sh
```

### 4. **Makefile Commands**
```bash
make test-gasgrief                    # Run all tests
make test-gasgrief-attack             # Gas griefing attack tests
make analyze-gasgrief-consumption     # Gas consumption analysis
make demo-gasgrief                    # Complete demonstration
```

## ⚠️ Security Considerations

### **Development Guidelines**
1. **Always bound loops** - Never allow unlimited iterations
2. **Implement pagination** - Break large operations into batches  
3. **Monitor gas usage** - Track and limit gas consumption
4. **Add circuit breakers** - Emergency stops when gas runs low
5. **Test with large inputs** - Verify behavior under stress

### **Code Review Checklist**
- [ ] All loops have maximum iteration limits
- [ ] User input cannot control loop bounds
- [ ] Gas-intensive operations are paginated
- [ ] Circuit breakers protect against gas exhaustion
- [ ] Functions have reasonable gas limits

## 🔍 Detection Methods

### **Static Analysis**
- Look for `for` loops without bounds checking
- Identify user-controlled loop parameters
- Find functions that scale with array length

### **Dynamic Testing**
- Test with large input arrays
- Monitor gas consumption patterns
- Verify function behavior near gas limits

### **Gas Profiling**
```solidity
uint256 startGas = gasleft();
vulnerableFunction(largeInput);
uint256 gasUsed = startGas - gasleft();
console.log("Gas used:", gasUsed);
```

## 💰 Real-World Impact

### **Historical Incidents**
- **GovernorBravo DoS**: Unbounded proposal loops
- **Multi-signature wallet attacks**: Large transaction batches
- **DEX front-running**: Gas price manipulation attacks

### **Economic Impact**
- Contract becomes completely unusable
- Funds can become locked if operations fail
- Network congestion from failed transactions
- High gas costs for legitimate users

## 🎯 Challenge Completion

Complete the challenge by:

1. **Demonstrate Attack**: Successfully perform gas griefing attack
2. **Show DoS Impact**: Prove contract becomes unusable  
3. **Implement Mitigation**: Create gas-efficient alternatives
4. **Verify Solutions**: Test mitigations prevent attacks

## 📚 Additional Resources

### **Gas Optimization**
- [Ethereum Gas Optimization Guide](https://ethereum.org/en/developers/docs/gas/)
- [Solidity Gas Optimization Patterns](https://github.com/ethereum/solidity/issues)

### **DoS Prevention**
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [Gas Griefing Attack Examples](https://github.com/sigp/solidity-security-blog)

### **Tools**
- **Forge Gas Reports**: `forge test --gas-report`
- **Mythril**: Static analysis for gas issues
- **Slither**: Detects unbounded loop vulnerabilities

---

**Remember**: Gas griefing attacks are subtle but devastating. Always design with gas limits in mind! ⛽🛡️