# CrackMe – Solution Walkthrough

1. **Map the storage layout**
   - `secret` is an immutable `bytes32`, so its slot is fixed at deployment and never changes.
   - `attempt()` only checks the *first* 16 bytes (`bytes16(secret)`).
   - The contract kindly exposes `revealByte(uint8)` which returns a single byte of that prefix.

2. **Recover the key**
   - Call `revealByte(i)` for `i = 0…15`.
   - Pack the bytes into a `bytes` array and load them into a `bytes16` (cf. `_recoverKey()` in `CrackMeSolution.sol`).

3. **Calculate the checksum**
   - `nonce` starts at `0` and increments *before* the comparison thanks to `unchecked { nonce += 1; }`.
   - During the first call from the solver contract: `nonce == 1`.
   - The checksum condition becomes `uint64(uint160(msg.sender)) + 1`.
   - As long as the call comes from the solver contract itself, the checksum is deterministic.

4. **Trigger the solve**
   - Call `attempt(key, checksum)`.
   - `solved` flips to `true` and `solver` records the calling contract.

5. **Alternative approach (assembly)**
   - `CrackMeAssembly.recoverKey()` replicates the same byte-by-byte leak gathering via `staticcall`.
   - It illustrates how to assemble ABI-encoded calldata and responses without high-level Solidity helpers.

6. **Validation**
   - `forge test --match-path "challenges/06-CrackMe/test/*.t.sol"` asserts both the high-level and assembly implementations work and that incorrect inputs revert as expected.
