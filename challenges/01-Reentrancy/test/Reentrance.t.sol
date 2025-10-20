// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Reentrance.sol";
import "../src/ReentrancyExploit.sol";
import {ReentrancyAssemblyAttack} from "../src/ReentrancyAssemblyAttack.sol";

contract ReentranceTest is Test {
    Reentrance reentrance;
    ReentrancyExploit exploit;
    ReentrancyAssemblyAttack assemblyAttack;

    function setUp() public {
        reentrance = new Reentrance();
        exploit = new ReentrancyExploit(address(reentrance));
        assemblyAttack = new ReentrancyAssemblyAttack();
        
        // Give the test contract working capital and pre-fund the challenge target
        vm.deal(address(this), 200 ether);
        vm.deal(address(reentrance), 10 ether);
    }

    function testDonation() public {
        reentrance.donate{value: 1 ether}(address(this));
        assertEq(reentrance.balanceOf(address(this)), 1 ether);
        assertEq(address(reentrance).balance, 11 ether); // 10 from setup + 1 from donation
    }

    function testExploit() public {
        reentrance.donate{value: 10 ether}(address(this));
        
        exploit.attack{value: 1 ether}();
        
        assertEq(address(reentrance).balance, 0);
        assertGt(address(exploit).balance, 1 ether);
    }

    function testReentrancyExploit() public {
        reentrance.donate{value: 10 ether}(address(this));
        
        // Initial balance (10 from setup + 10 from donation)
        uint256 initialBalance = address(reentrance).balance;
        assertEq(initialBalance, 20 ether);
        
        exploit.attack{value: 1 ether}();
        
        // Contract should be drained
        assertEq(address(reentrance).balance, 0);
    }

    function testTargetDrained() public {
        reentrance.donate{value: 5 ether}(address(this));
        
        exploit.attack{value: 1 ether}();
        
        // Verify drained
        assertEq(address(reentrance).balance, 0);
    }

    function testAssemblyAttack() public {
        vm.deal(address(this), 100 ether);
        
        // Initial reentrance balance
        uint256 initialBalance = address(reentrance).balance;
        
        // Execute assembly attack - donate 1 ether to establish balance
        assemblyAttack.donate{value: 1 ether}(address(reentrance));
        
        // Verify donation worked
        assertEq(reentrance.balanceOf(address(assemblyAttack)), 1 ether);
        assertEq(address(reentrance).balance, initialBalance + 1 ether);
        
        assemblyAttack.attack();
        
        // Check that assembly attack drained the contract
        assertEq(address(reentrance).balance, 0);
        assertGt(address(assemblyAttack).balance, 1 ether);
        
        // Check iteration count
        uint256 iterations = assemblyAttack.getIterationCount();
        assertGt(iterations, 0);
        console.log("Attack completed in iterations:", iterations);
        
        // Get attack stats
        (
            address target, 
            uint256 amount, 
            uint256 iters, 
            uint256 stolen, 
            uint256 targetBal
        ) = assemblyAttack.getAttackStats();
        
        assertEq(target, address(reentrance));
        assertEq(amount, 1 ether);
        assertEq(iters, iterations);
        assertEq(stolen, address(assemblyAttack).balance);
        assertEq(targetBal, 0);
        
        console.log("Total stolen:", stolen);
    }

    function testAssemblyAttackSafety() public {
        // Fund with lots of ETH to test safety limits
        vm.deal(address(reentrance), 100 ether);
        vm.deal(address(this), 10 ether);
        
        assemblyAttack.donate{value: 1 ether}(address(reentrance));
        assemblyAttack.attack();
        
        // Should not exceed max iterations (50)
        uint256 iterations = assemblyAttack.getIterationCount();
        assertLe(iterations, 50);
        console.log("Iterations with 100 ETH target:", iterations);
        
        // Contract should be significantly drained (might not be 0 due to iteration limit)
        uint256 remaining = address(reentrance).balance;
        console.log("Remaining balance:", remaining);
        
        // With 1 ETH attack amount and 50 iterations, should drain at least 50 ETH
        assertLe(remaining, 51 ether); // Allow 1 ETH buffer
    }

    function testAssemblySelectorCalculation() public {
        bytes4 selector = assemblyAttack.calculateSelector("withdraw(uint256)");
        assertEq(uint32(selector), uint32(0x2e1a7d4d));
        
    bytes4 donateSelector = assemblyAttack.calculateSelector("donate(address)");
    assertEq(uint32(donateSelector), uint32(0x00362a95));
        
        console.log("withdraw(uint256) selector:", uint32(selector));
        console.log("donate(address) selector:", uint32(donateSelector));
    }

    function testAssemblyCallEncoding() public {
        bytes memory data = assemblyAttack.encodeWithdrawCall(1 ether);
        assertEq(data.length, 36);
        
        // Check selector
        bytes4 selector;
        assembly {
            selector := mload(add(data, 0x20))
        }
        assertEq(uint32(selector), uint32(0x2e1a7d4d));
        
        // Check amount
        uint256 amount;
        assembly {
            amount := mload(add(data, 0x24))
        }
        assertEq(amount, 1 ether);
        
        console.log("Encoded call data:");
        console.logBytes(data);
    }

    function testAssemblyWithdrawOnlyOwner() public {
        vm.deal(address(this), 10 ether);
        
        assemblyAttack.donate{value: 1 ether}(address(reentrance));
        assemblyAttack.attack();
        
        // Try to withdraw as non-owner (should fail)
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        assemblyAttack.withdraw();
        
        // Owner can withdraw
        uint256 balanceBefore = address(this).balance;
        assemblyAttack.withdraw();
        assertGt(address(this).balance, balanceBefore);
        assertEq(address(assemblyAttack).balance, 0);
    }

    function testAssemblyTargetBalance() public {
        vm.deal(address(reentrance), 50 ether);
        assemblyAttack.donate{value: 1 ether}(address(reentrance));

        uint256 targetBal = assemblyAttack.getTargetBalance();
        assertEq(targetBal, address(reentrance).balance);
    }

    function testAssemblyEmergencyStop() public {
        vm.deal(address(this), 10 ether);
        
        assemblyAttack.donate{value: 1 ether}(address(reentrance));
        assemblyAttack.attack();
        
        uint256 stolenAmount = address(assemblyAttack).balance;
        assertGt(stolenAmount, 0);
        
        // Non-owner cannot emergency stop
        vm.prank(address(0xDEAD));
        vm.expectRevert();
        assemblyAttack.emergencyStop();
        
        // Owner can emergency stop
        uint256 balanceBefore = address(this).balance;
        uint256 codeSizeBefore = address(assemblyAttack).code.length;
        assemblyAttack.emergencyStop();
        uint256 codeSizeAfter = address(assemblyAttack).code.length;
        
        // Cancun-era EVM leaves code intact, so accept either fully destroyed or unchanged code
        assertTrue(codeSizeAfter == 0 || codeSizeAfter == codeSizeBefore);
        assertGt(address(this).balance, balanceBefore);

        // Any further interaction should revert because storage is wiped
        vm.expectRevert();
        assemblyAttack.attack();
    }

    function testCompleteAttackFlow() public {
        console.log("=== Complete Assembly Attack Flow ===");
        
        // Setup
        vm.deal(address(this), 10 ether);
        vm.deal(address(reentrance), 25 ether);
        
        console.log("Initial reentrance balance:", address(reentrance).balance);
        console.log("Attacker balance:", address(this).balance);
        
        console.log("\n[1] Donating 1 ETH...");
        assemblyAttack.donate{value: 1 ether}(address(reentrance));
        console.log("Reentrance balance after donation:", address(reentrance).balance);
        
        console.log("\n[2] Launching attack...");
        assemblyAttack.attack();
        
        uint256 iterations = assemblyAttack.getIterationCount();
        console.log("Attack completed in", iterations, "iterations");
        console.log("Reentrance balance after attack:", address(reentrance).balance);
        console.log("Exploit contract balance:", address(assemblyAttack).balance);
        
        console.log("\n[3] Withdrawing stolen funds...");
        assemblyAttack.withdraw();
        console.log("Final attacker balance:", address(this).balance);
        
        assertEq(address(reentrance).balance, 0);
        assertEq(address(assemblyAttack).balance, 0);
        assertGt(address(this).balance, 9 ether); 
        
        console.log("\n=== Attack Successful! ===");
    }

    // Receive function to accept ETH
    receive() external payable {}
}