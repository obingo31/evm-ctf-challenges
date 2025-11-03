// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ManipulateMint.sol";

/**
 * @title ManipulateMintTest - Test Suite for Storage Slot Manipulation Challenge
 * @dev Comprehensive test suite that demonstrates the vulnerability and validates the exploit
 */
contract ManipulateMintTest is Test {
    ManipulateMint public token;
    
    address public owner = address(0x1);
    address public player = address(0x2);
    address public other = address(0x3);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ChallengeSolved(address solver, uint256 balance);

    function setUp() public {
        vm.startPrank(owner);
        token = new ManipulateMint();
        vm.stopPrank();
    }

    /**
     * @dev Test basic ERC-20 functionality works correctly
     */
    function testBasicERC20Functionality() public {
        assertEq(token.name(), "VulnerableToken");
        assertEq(token.symbol(), "VULN");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.owner(), owner);
        assertFalse(token.isSolved());
    }

    /**
     * @dev Test that safe minting works correctly and respects max supply
     */
    function testSafeMintRespectsBounds() public {
        uint256 maxSupply = token.MAX_SUPPLY();
        uint256 mintAmount = maxSupply / 2;

        vm.startPrank(owner);
        
        // Should succeed within limits
        token.safeMint(owner, mintAmount);
        assertEq(token.balanceOf(owner), mintAmount);
        assertEq(token.totalSupply(), mintAmount);

        // Should succeed for remaining amount
        token.safeMint(other, maxSupply - mintAmount);
        assertEq(token.balanceOf(other), maxSupply - mintAmount);
        assertEq(token.totalSupply(), maxSupply);

        // Should fail when exceeding max supply
        vm.expectRevert("Exceeds max supply");
        token.safeMint(owner, 1);
        
        vm.stopPrank();
    }

    /**
     * @dev Test the vulnerable manipulateMint function
     */
    function testManipulateMintVulnerability() public {
        uint256 maxSupply = token.MAX_SUPPLY();
        uint256 exploitAmount = maxSupply * 10; // 10x the max supply!

        vm.startPrank(owner);
        
        // Record initial state
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialTotalSupply = token.totalSupply();
        
        // Expect Transfer event (though total supply won't be updated)
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), owner, exploitAmount);
        
        // Execute the exploit
        token.manipulateMint(exploitAmount);
        
        // Verify the exploit worked
        assertEq(token.balanceOf(owner), exploitAmount);
        
        // Critical vulnerability: total supply is NOT updated!
        assertEq(token.totalSupply(), initialTotalSupply);
        
        // Verify storage inconsistency
        (uint256 reportedTotal, uint256 ownerBalance, bool inconsistent) = token.getStorageInconsistency();
        assertEq(reportedTotal, initialTotalSupply);
        assertEq(ownerBalance, exploitAmount);
        assertTrue(inconsistent);
        
        vm.stopPrank();
    }

    /**
     * @dev Test that only owner can call manipulateMint
     */
    function testManipulateMintOnlyOwner() public {
        vm.startPrank(player);
        
        vm.expectRevert("Not the owner");
        token.manipulateMint(1000);
        
        vm.stopPrank();
    }

    /**
     * @dev Test the challenge completion mechanism
     */
    function testChallengeCompletion() public {
        uint256 maxSupply = token.MAX_SUPPLY();
        uint256 exploitAmount = maxSupply + 1;

        vm.startPrank(owner);
        
        // First, use manipulateMint to exceed max supply
        token.manipulateMint(exploitAmount);
        
        // Verify balance exceeds max supply
        assertGt(token.balanceOf(owner), maxSupply);
        
        // Expect ChallengeSolved event
        vm.expectEmit(true, false, false, true);
        emit ChallengeSolved(owner, exploitAmount);
        
        // Complete the challenge
        token.checkSolution();
        
        // Verify challenge is solved
        assertTrue(token.isSolved());
        
        vm.stopPrank();
    }

    /**
     * @dev Test that checkSolution fails if balance doesn't exceed max supply
     */
    function testChallengeFailsWithInsufficientBalance() public {
        uint256 maxSupply = token.MAX_SUPPLY();
        
        vm.startPrank(owner);
        
        // Mint exactly max supply (should not trigger solution)
        token.manipulateMint(maxSupply);
        
        vm.expectRevert("Balance must exceed max supply");
        token.checkSolution();
        
        assertFalse(token.isSolved());
        
        vm.stopPrank();
    }

    /**
     * @dev Test storage slot calculation correctness
     */
    function testStorageSlotCalculation() public {
        // This test verifies that our assembly calculation matches Solidity's mapping storage
        uint256 testAmount = 12345;
        
        vm.startPrank(owner);
        
        // Use manipulateMint to set balance
        token.manipulateMint(testAmount);
        
        // Verify the balance was set correctly
        assertEq(token.balanceOf(owner), testAmount);
        
        // Test with different address to ensure slot calculation is address-specific
        vm.stopPrank();
        vm.startPrank(player);
        
        // Player should have 0 balance (manipulateMint only affects owner)
        assertEq(token.balanceOf(player), 0);
        
        vm.stopPrank();
    }



    /**
     * @dev Test that regular ERC-20 transfers work after manipulation
     */
    function testTransfersAfterManipulation() public {
        uint256 exploitAmount = 1000000 * 10**18;
        
        vm.startPrank(owner);
        
        // Manipulate balance
        token.manipulateMint(exploitAmount);
        
        // Transfer some tokens to another address
        uint256 transferAmount = 100000 * 10**18;
        token.transfer(other, transferAmount);
        
        // Verify balances
        assertEq(token.balanceOf(owner), exploitAmount - transferAmount);
        assertEq(token.balanceOf(other), transferAmount);
        
        // Total supply still inconsistent
        assertLt(token.totalSupply(), token.balanceOf(owner) + token.balanceOf(other));
        
        vm.stopPrank();
    }

    /**
     * @dev Fuzz test: manipulateMint with various amounts
     */
    function testFuzzManipulateMint(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint128).max); // Reasonable bounds
        
        vm.startPrank(owner);
        
        token.manipulateMint(amount);
        assertEq(token.balanceOf(owner), amount);
        
        // Total supply should remain 0 (demonstrating the vulnerability)
        assertEq(token.totalSupply(), 0);
        
        vm.stopPrank();
    }

    /**
     * @dev Gas usage comparison between safe mint and manipulate mint
     */
    function testGasUsageComparison() public {
        uint256 amount = 1000 * 10**18;
        
        vm.startPrank(owner);
        
        // Measure gas for safe mint
        uint256 gasStart = gasleft();
        token.safeMint(other, amount);
        uint256 safeMintGas = gasStart - gasleft();
        
        // Measure gas for manipulate mint
        gasStart = gasleft();
        token.manipulateMint(amount);
        uint256 manipulateGas = gasStart - gasleft();
        
        // Manipulate mint should use less gas (no safety checks)
        assertLt(manipulateGas, safeMintGas);
        
        vm.stopPrank();
    }
}