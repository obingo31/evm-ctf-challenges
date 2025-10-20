# Challenge 02: Fallback Takeover

## 🎯 Challenge Goal

Seize ownership of the vulnerable `Fallback` contract and drain its balance with a dust contribution followed by a direct ether transfer.

## 📋 Difficulty

Beginner ⭐

## 🔍 Vulnerability Overview

The early Ethernaut `Fallback` level exposes two escalation paths:

1. **Contribution race** – contribute more than the deployer (funded with 1000 ether by default) to take ownership the intended way.
2. **Fallback takeover** – call `contribute()` once, then trigger the `receive()` handler with a minimal transfer. The handler checks only that the caller has a non-zero contribution, so any contributor can hijack the owner slot.

Because option two costs almost nothing, it is the focus of this challenge.

### Key Bug

```solidity
receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender; // Ownership flips to any contributor
}
```

## 💥 Exploit Walkthrough

1. Call `contribute()` with less than 0.001 ether.
2. Send any positive amount of ETH directly to the contract so `receive()` executes.
3. You are now the owner; call `withdraw()` and drain the balance.

## 🧨 Assembly Attack (Included)

`FallbackAssemblyAttack` performs the exploit entirely in inline assembly:

- Computes function selectors manually with `keccak256`.
- Issues back-to-back `call` opcodes to `contribute()` and the bare `receive()` entry point.
- Uses `staticcall` to confirm ownership via `owner()`.
- Calls `withdraw()` and returns the ether to the attacker contract deployer.

Invoke `attack(address target)` with at least `0.0002 ether` to cover the outbound transactions, then call `withdraw()` to collect the funds.

## 🧪 Testing

```bash
# Foundry tests
cd challenges/02-Fallback
forge test

# Echidna property fuzzing (run from challenges/02-Fallback)
export PATH="$HOME/.local/bin:$PATH"
echidna echidna/FallbackEchidna.sol \
    --contract FallbackEchidna \
    --config echidna/fallback.yaml \
    --test-limit 10000
```

The Echidna harness (`FallbackEchidna`) asserts that the original deployer remains owner. Echidna quickly falsifies the property with the contribution plus direct-transfer sequence, emitting reproducers under `echidna/corpus/` (ignored by git).

## 📚 Further Reading

- [Ethernaut Level 1: Fallback](https://ethernaut.openzeppelin.com/level/0x709b10ec3A1d1cf2659cE1Be219964aB2b9029A3)
- [Trail of Bits – Echidna](https://github.com/crytic/echidna)
- [OpenZeppelin – Ownable](https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable)

---

⚠️ **Educational use only.** Do not deploy or exploit vulnerable contracts outside controlled environments.
