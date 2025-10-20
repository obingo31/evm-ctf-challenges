// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Telephone.sol";
import "../src/TelephoneExploit.sol";
import {TelephoneAssemblyAttack} from "../src/TelephoneAssemblyAttack.sol";

contract TelephoneTest is Test {
    Telephone telephone;
    TelephoneExploit exploit;
    TelephoneAssemblyAttack assemblyAttack;
    
    address deployer;
    address attacker;
    address newOwner;

    function setUp() public {
        deployer = address(this);
        attacker = address(0x1337);
        newOwner = address(0xdead);
        
        // Deploy contracts
        telephone = new Telephone();
        exploit = new TelephoneExploit(address(telephone));
        assemblyAttack = new TelephoneAssemblyAttack();
        
        // Verify initial setup
        assertEq(telephone.owner(), deployer);
        assertEq(exploit.owner(), deployer);
    }

    function testInitialState() public {
        assertEq(telephone.owner(), deployer);
        assertEq(telephone.getOwner(), deployer);
    }

    function testDirectCallFails() public {
        // Simulate direct call from EOA where tx.origin == msg.sender
        address eoa = address(0x999);
        vm.prank(eoa, eoa); // Both tx.origin and msg.sender will be eoa
        telephone.changeOwner(newOwner);
        
        // Owner should remain unchanged because tx.origin == msg.sender
        assertEq(telephone.owner(), deployer);
    }

    function testExploitWithInterface() public {
        // Execute exploit using interface method
        exploit.exploitWithInterface(newOwner);
        
        // Verify ownership changed
        assertEq(telephone.owner(), newOwner);
        assertEq(exploit.getTargetOwner(), newOwner);
    }

    function testExploitWithLowLevelCall() public {
        // Execute exploit using low-level call
        exploit.exploit(newOwner);
        
        // Verify ownership changed
        assertEq(telephone.owner(), newOwner);
        assertEq(exploit.getTargetOwner(), newOwner);
    }

    function testExploitOnlyOwner() public {
        // Try to call exploit from non-owner address
        vm.prank(attacker);
        vm.expectRevert("Only owner can execute exploit");
        exploit.exploit(newOwner);
        
        // Owner should remain unchanged
        assertEq(telephone.owner(), deployer);
    }

    function testAssemblyAttackSetTarget() public {
        // Set target using assembly attack
        assemblyAttack.setTarget(address(telephone));
        
        // Verify target was set
        assertEq(assemblyAttack.getTarget(), address(telephone));
    }

    function testAssemblyAttackOnlyOwner() public {
        // Try to set target from non-owner address
        vm.prank(attacker);
        vm.expectRevert();
        assemblyAttack.setTarget(address(telephone));
    }

    function testAssemblyAttackExploit() public {
        // Set target first
        assemblyAttack.setTarget(address(telephone));
        
        // Execute assembly attack
        assemblyAttack.attack(newOwner);
        
        // Verify ownership changed
        assertEq(telephone.owner(), newOwner);
        
        // Verify exploit using assembly verification
        (bool success, address currentOwner) = assemblyAttack.verifyExploit();
        assertTrue(success);
        assertEq(currentOwner, newOwner);
    }

    function testAssemblyAttackRequiresTarget() public {
        // Try to attack without setting target first
        vm.expectRevert("Target not set");
        assemblyAttack.attack(newOwner);
    }

    function testAssemblyAttackOnlyOwnerCanAttack() public {
        // Set target first
        assemblyAttack.setTarget(address(telephone));
        
        // Try to attack from non-owner address
        vm.prank(attacker);
        vm.expectRevert();
        assemblyAttack.attack(newOwner);
        
        // Owner should remain unchanged
        assertEq(telephone.owner(), deployer);
    }

    function testComputeSelector() public {
        // Test the educational selector computation function
        bytes4 selector = assemblyAttack.computeSelector("changeOwner(address)");
        assertEq(selector, bytes4(keccak256("changeOwner(address)")));
        
        bytes4 ownerSelector = assemblyAttack.computeSelector("owner()");
        assertEq(ownerSelector, bytes4(keccak256("owner()")));
    }

    function testMultipleExploits() public {
        address secondNewOwner = address(0xbeef);
        
        // First exploit with standard contract
        exploit.exploit(newOwner);
        assertEq(telephone.owner(), newOwner);
        
        // Second exploit with assembly attack (change owner again)
        assemblyAttack.setTarget(address(telephone));
        assemblyAttack.attack(secondNewOwner);
        assertEq(telephone.owner(), secondNewOwner);
    }

    function testTxOriginVsMsgSender() public {
        // Create a test to demonstrate the vulnerability
        address user = address(0x999);
        
        // Fund the user and simulate transaction
        vm.deal(user, 1 ether);
        
        // Direct call fails (tx.origin == msg.sender)
        vm.prank(user, user); // Both tx.origin and msg.sender are user
        telephone.changeOwner(newOwner);
        assertEq(telephone.owner(), deployer); // Unchanged
        
        // Call through exploit succeeds (tx.origin != msg.sender)
        // tx.origin = user, msg.sender = exploit contract
        vm.startPrank(user);
        TelephoneExploit userExploit = new TelephoneExploit(address(telephone));
        userExploit.exploit(newOwner);
        assertEq(telephone.owner(), newOwner); // Changed!
        vm.stopPrank();
    }

    function testOwnershipTransferEvent() public {
        // Test that ownership transfer events are emitted
        vm.expectEmit(true, true, false, true);
        emit Telephone.OwnershipTransferred(deployer, newOwner);
        
        exploit.exploit(newOwner);
    }

    function testExploitEvent() public {
        // Test that exploit events are emitted
        vm.expectEmit(true, true, false, true);
        emit TelephoneExploit.ExploitExecuted(address(telephone), newOwner);
        
        exploit.exploit(newOwner);
    }

    function testAssemblyAttackEvents() public {
        // Test that events are emitted (can't easily test exact match due to assembly)
        // Just verify the functions execute without reverting
        assemblyAttack.setTarget(address(telephone));
        assemblyAttack.attack(newOwner);
        
        // Verify the attack succeeded
        assertEq(telephone.owner(), newOwner);
    }

    // Fuzz testing
    function testFuzzExploit(address randomNewOwner) public {
        vm.assume(randomNewOwner != address(0));
        vm.assume(randomNewOwner != deployer);
        
        exploit.exploit(randomNewOwner);
        assertEq(telephone.owner(), randomNewOwner);
    }

    function testFuzzAssemblyAttack(address randomNewOwner) public {
        vm.assume(randomNewOwner != address(0));
        vm.assume(randomNewOwner != deployer);
        
        assemblyAttack.setTarget(address(telephone));
        assemblyAttack.attack(randomNewOwner);
        assertEq(telephone.owner(), randomNewOwner);
    }
}