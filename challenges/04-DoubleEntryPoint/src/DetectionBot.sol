// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./DoubleEntryPoint.sol";

/**
 * @title DoubleEntryPointFortaBot
 * @notice Advanced assembly-based detection bot for preventing vault drainage attacks
 * @dev Demonstrates sophisticated inline assembly techniques including:
 *      - Manual storage slot manipulation
 *      - Dynamic function selector calculation using keccak256
 *      - Advanced calldata parsing and validation
 *      - Assembly-based external calls with proper error handling
 *      - Custom revert message construction
 * 
 * VULNERABILITY ANALYSIS:
 * The attack vector is: vault.sweepToken(legacyToken) -> legacyToken.transfer() 
 * -> doubleEntryPoint.delegateTransfer(to, value, origSender=vault)
 * 
 * When vault calls sweepToken(legacyToken), it triggers:
 * 1. legacyToken.transfer(recipient, balance) 
 * 2. Since legacyToken has a delegate, it calls doubleEntryPoint.delegateTransfer()
 * 3. delegateTransfer gets called with origSender = vault address
 * 4. This transfers tokens FROM the vault TO the recipient, draining the vault
 * 
 * DETECTION STRATEGY:
 * Monitor calls to delegateTransfer and check if origSender == cryptoVault address.
 * If so, raise an alert to prevent the transaction.
 */
contract DoubleEntryPointFortaBot is IDetectionBot {
    IForta forta;
    address vault;

    /**
     * @notice Initialize the detection bot using pure assembly for storage
     * @param _forta Address of the Forta monitoring system
     * @param _vault Address of the crypto vault to monitor
     * @dev Uses assembly to directly manipulate storage slots for gas efficiency
     */
    constructor(IForta _forta, address _vault) {
        // Pure assembly implementation for educational purposes
        // Demonstrates direct storage slot manipulation
        assembly {
            sstore(forta.slot, _forta)
            sstore(vault.slot, _vault)
        }
    }

    /**
     * @notice Handle transaction monitoring with advanced assembly techniques
     * @param user The user associated with this transaction
     * @param msgData The transaction calldata to analyze
     * @dev Pure assembly implementation demonstrating:
     *      - Access control verification
     *      - Dynamic function selector calculation
     *      - Calldata parsing and validation
     *      - External contract calls
     *      - Custom error handling
     */
    function handleTransaction(address user, bytes calldata msgData) external {
        assembly {
            // Load Forta address from storage for access control and later use
            let _forta := sload(forta.slot)
            
            // Access control: Verify caller is the Forta contract
            if iszero(eq(caller(), _forta)) {
                // Construct custom revert message using assembly
                let fmp := mload(0x40)
                mstore(fmp, "Error(string)")
                mstore(fmp, keccak256(fmp, 13))
                mstore(add(fmp, 4), 0x20)
                mstore(add(fmp, 0x24), 27)
                mstore(add(fmp, 0x44), "request not sent from Forta")
                revert(fmp, 0x64)
            }

            // === DYNAMIC FUNCTION SELECTOR CALCULATION ===
            // Calculate delegateTransfer(address,uint256,address) selector using keccak256
            let fmp := mload(0x40)
            mstore(fmp, "delegateTransfer(address,uint256")
            mstore(add(fmp, 0x20), ",address)")
            mstore(fmp, keccak256(fmp, 41))
            
            // Create mask to extract only the first 4 bytes (function selector)
            let selectorMask := shl(224, sub(exp(2, 32), 1))
            let delegateTransferSelector := and(mload(fmp), selectorMask)

            // === CALLDATA PARSING ===
            // Extract function selector from the provided msgData
            let msgSelector := and(calldataload(msgData.offset), selectorMask)
            
            // Extract origSender parameter (3rd parameter at offset 0x44)
            // delegateTransfer(address to, uint256 value, address origSender)
            // Offset: 4 bytes (selector) + 32 bytes (to) + 32 bytes (value) = 0x44
            let origSender := calldataload(add(msgData.offset, 0x44))

            // === VULNERABILITY DETECTION ===
            // Check if this is a delegateTransfer call AND origSender is the vault
            if and(eq(msgSelector, delegateTransferSelector), eq(origSender, sload(vault.slot))) {
                // ATTACK DETECTED! Construct call to forta.raiseAlert(user)
                
                // Calculate raiseAlert(address) selector
                mstore(0, "raiseAlert(address)")
                mstore(0, keccak256(0, 19))
                
                // Prepare call parameters
                mstore(4, user)
                
                // Execute external call to raise alert
                let success := call(gas(), _forta, 0, 0, 0x24, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }
        }
    }
}

