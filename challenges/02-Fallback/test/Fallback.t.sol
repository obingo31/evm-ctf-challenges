// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Fallback.sol";
import "../src/FallbackAssemblyAttack.sol";

contract FallbackTest is Test {
    Fallback internal target;
    FallbackAssemblyAttack internal attacker;

    function setUp() public {
        target = new Fallback();
        attacker = new FallbackAssemblyAttack();

        // Fund the target so there is value to steal
        vm.deal(address(target), 5 ether);

        // Ensure the test contract can finance the assembly exploit
        vm.deal(address(this), 1 ether);
    }

    function testOwnershipFlipsAfterReceive() public {
        attacker.attack{value: 0.0002 ether}(address(target));
        assertEq(target.owner(), address(attacker));
    }

    function testAssemblyAttackDrainsBalance() public {
        uint256 initialTargetBalance = address(target).balance;
        assertGt(initialTargetBalance, 0);

        attacker.attack{value: 0.0002 ether}(address(target));
        assertEq(target.owner(), address(attacker));

        uint256 ownerBalanceBefore = address(this).balance;
        attacker.withdraw();

        assertEq(address(target).balance, 0, "target should be empty after withdraw");
        assertGt(address(this).balance, ownerBalanceBefore, "owner should receive stolen funds");
    }

    // Allow this test contract to receive ETH from the attacker withdrawal
    receive() external payable {}
}
