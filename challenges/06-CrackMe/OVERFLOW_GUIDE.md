# Overflow Guide – CrackMe

`CrackMe.attempt()` increments `nonce` inside an `unchecked` block:

```solidity
unchecked {
    nonce += 1;
}
```

With Solidity 0.8.x, arithmetic is *safe* by default and would revert on overflow. Wrapping it in `unchecked` restores the pre-0.8 behaviour, allowing the value to wrap silently once it hits `type(uint64).max`.

Why it matters:

- `attempt()` compares the supplied checksum against `uint64(uint160(msg.sender)) + nonce` computed inside an `unchecked` block.
- On the very first call from a solver contract the checksum must simply equal `uint64(uint160(address(solver))) + 1`.
- Later calls could deliberately overflow `nonce` to bypass a naive checksum check, which mirrors real-world bugs where developers rely on monotonically increasing counters but disable overflow checks for gas savings.

Takeaways:

- Treat `unchecked` blocks with suspicion; they are often added for micro-optimisations and can hide logic bugs.
- Always model the overflow boundary (`2**64 - 1` here) when designing or auditing puzzles that involve wrapping arithmetic.
