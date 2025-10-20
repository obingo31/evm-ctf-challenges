pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Reentrance.sol";
import "../src/ReentrancyExploit.sol";

contract ReentranceTest is Test {
    Reentrance reentrance;
    ReentrancyExploit exploit;

    function setUp() public {
        reentrance = new Reentrance();
        exploit = new ReentrancyExploit(address(reentrance));
    }

    function testDonation() public {
        reentrance.donate{value: 1 ether}(address(this));
        assertEq(reentrance.balanceOf(address(this)), 1 ether);
        assertEq(address(reentrance).balance, 1 ether);
    }

    function testExploit() public {
        // Fund the reentrance contract
        reentrance.donate{value: 10 ether}(address(exploit));
        
        // Execute attack
        exploit.attack{value: 1 ether}();
        
        // Check that exploit drained the contract
        assertEq(address(reentrance).balance, 0);
        assertGt(address(exploit).balance, 10 ether);
    }

    function testReentrancyExploit() public {
        // Fund the contract with 10 ether
        reentrance.donate{value: 10 ether}(address(exploit));
        
        // Initial balance
        uint256 initialBalance = address(reentrance).balance;
        assertEq(initialBalance, 10 ether);
        
        // Execute attack
        exploit.attack{value: 1 ether}();
        
        // Contract should be drained
        assertEq(address(reentrance).balance, 0);
    }

    function testTargetDrained() public {
        // Fund the contract
        reentrance.donate{value: 5 ether}(address(exploit));
        
        // Attack
        exploit.attack{value: 1 ether}();
        
        // Verify drained
        assertEq(address(reentrance).balance, 0);
    }
}