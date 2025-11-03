# 🔐 EVM CTF Challenges

Learn EVM Assembly through hands-on Ethernaut CTF challenges. This repository contains security-focused Solidity exercises with detailed inline assembly exploits and explanations.

![Solidity](https://img.shields.io/badge/Solidity-^0.8.18-363636?style=for-the-badge&logo=solidity)
![Foundry](https://img.shields.io/badge/Foundry-Latest-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## 🎯 Learning Objectives

- Master EVM opcodes and inline assembly
- Understand common smart contract vulnerabilities
- Learn exploitation techniques (for educational purposes)
- Practice secure coding patterns
- Deep dive into Ethereum's virtual machine

## 📚 Challenges

| # | Challenge | Difficulty | Topic | Status |
|---|-----------|------------|-------|--------|
| 01 | [Reentrancy](./challenges/01-Reentrancy/) | ⭐⭐⭐ | External Calls | ✅ Complete |
| 02 | [Fallback](./challenges/02-Fallback/) | ⭐ | Fallback Ownership | ✅ Complete |
| 03 | [Telephone](./challenges/03-Telephone/) | ⭐ | tx.origin Attack | ✅ Complete |
| 04 | [DoubleEntryPoint](./challenges/04-DoubleEntryPoint/) | ⭐⭐⭐ | Delegation Attack | ✅ Complete |
| 05 | [Casino](./challenges/05-Casino/) | ⭐⭐ | Predictable RNG | ✅ Complete |
| 06 | [CrackMe](./challenges/06-CrackMe/) | ⭐⭐⭐ | Storage Leakage | ✅ Complete |
| 07 | [PrivilegeFinance](./challenges/07-PrivilegeFinance/) | ⭐⭐⭐ | Signature Spoofing | ✅ Complete |
| 08 | [LittleMoney](./challenges/08-LittleMoney/) | ⭐⭐⭐ | Function Pointer Manipulation | ✅ Complete |
| 09 | [ManipulateMint](./challenges/09-ManipulateMint/) | ⭐⭐⭐ | Storage Slot Manipulation | ✅ Complete |
| 11 | [GasGrief](./challenges/11-GasGrief/) | ⭐⭐⭐⭐ | Gas Griefing & DoS | ✅ Complete |
| 12 | [TimeLocked](./challenges/12-TimeLocked/) | ⭐⭐⭐⭐ | Timestamp Manipulation | ✅ Complete |

## 🛠️ Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Basic Solidity knowledge
- Understanding of Ethereum concepts

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/obingo31/evm-ctf-challenges.git
cd evm-ctf-challenges

# Install dependencies
forge install

# Run tests for a specific challenge
forge test --match-path challenges/01-Reentrancy/test/*.t.sol -vvvv

# Test advanced challenges with Makefile
make test-gasgrief        # Gas griefing attacks
make test-timelocked      # Timestamp manipulation

# Run comprehensive demos
make demo-gasgrief        # Complete gas griefing demonstration
make demo-timelocked      # Timestamp attack showcase

# Run all tests
forge test -vvvv
```

## 📖 Documentation

- [Getting Started](./docs/getting-started.md) - Setup and basic concepts
- [EVM Opcodes Reference](./docs/evm-opcodes.md) - Complete opcode guide
- [Assembly Patterns](./docs/assembly-patterns.md) - Common assembly patterns

## 🎓 Learning Path

### Beginner

1. Read the challenge description
1. Analyze the vulnerable contract
1. Understand the vulnerability
1. Study the exploit code

### Intermediate

1. Rewrite exploits in pure assembly
1. Optimize gas usage
1. Add additional test cases

### Advanced

1. Create your own variations
1. Combine multiple vulnerabilities
1. Write security reports

## 🔬 Challenge Structure

Each challenge includes:

```text
challenge-name/
├── README.md           # Challenge description & walkthrough
├── src/
│   ├── Vulnerable.sol  # The vulnerable contract
│   └── Exploit.sol     # Exploit with assembly
└── test/
    └── Test.t.sol      # Comprehensive test suite
```

## 🧪 Testing

```bash
# Run specific test with detailed output
forge test --match-contract ReentranceTest -vvvv

# Advanced challenge testing with Makefile
make test-gasgrief-attack     # Gas griefing attack vectors
make test-timelocked-attack   # Timestamp manipulation attacks
make analyze-gasgrief-consumption  # Gas consumption analysis
make analyze-timelocked-timing     # Timestamp risk analysis

# Check gas reports
forge test --gas-report

# Generate coverage
forge coverage

# Run with traces
forge test --match-test testExploit -vvvvv
```

## 🎯 Advanced Challenges

The repository now includes **advanced vulnerability patterns**:

### 🔥 Challenge 11: GasGrief

- **Gas griefing attacks** and DoS vulnerabilities
- **25 comprehensive tests** covering all attack vectors
- **Unbounded loops** and quadratic gas consumption
- **Mitigation strategies** with pagination and gas limits
- **Interactive deployment** with real-time attack demos

### ⏰ Challenge 12: TimeLocked

- **Timestamp manipulation** vulnerabilities
- **21 comprehensive tests** with attack demonstrations
- **Governance timelock bypass** techniques
- **Secure timing mechanisms** and commit-reveal schemes
- **Risk analysis functions** for manipulation detection

Both challenges include:

- 🎯 **Production-ready contracts** with educational vulnerabilities
- 🧪 **Comprehensive test suites** with fuzz testing
- 📚 **Detailed documentation** with real-world examples
- 🚀 **Interactive deployment scripts** for live demonstrations
- 🛠️ **Enhanced Makefile commands** for specialized testing

## 🛡️ Security Disclaimer

⚠️ **FOR EDUCATIONAL PURPOSES ONLY**

This repository contains vulnerable smart contracts and exploits for learning purposes.

**DO NOT:**

- Deploy these contracts to mainnet
- Use these techniques maliciously
- Attack contracts without permission

**DO:**

- Learn from the vulnerabilities
- Practice secure coding
- Share knowledge responsibly

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Add new challenges
- Improve documentation
- Fix bugs
- Suggest improvements

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- [Ethernaut](https://ethernaut.openzeppelin.com/) by OpenZeppelin
- [Foundry](https://github.com/foundry-rs/foundry) by Paradigm
- [CTF Blockchain](https://github.com/minaminao/ctf-blockchain) by minaminao
- Ethereum security community

## 📬 Contact

**Obingo31** - Founder @ Malo Labs

- GitHub: [@obingo31](https://github.com/obingo31)
- Website: [malo-labs.gitbook.io](https://malo-labs.gitbook.io/documentation)

---

⭐ Star this repo if you find it helpful!

## Happy Hacking! 🔓
