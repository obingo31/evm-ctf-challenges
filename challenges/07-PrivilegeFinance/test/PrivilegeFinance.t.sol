// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/contracts/PrivilegeFinance.sol";
import "../src/contracts/PrivilegeFinanceExploit.sol";

contract PrivilegeFinanceTest is Test {
    PrivilegeFinance public finance;
    PrivilegeFinanceExploit public exploiter;

    function setUp() public {
        finance = new PrivilegeFinance();
        exploiter = new PrivilegeFinanceExploit();
    }

    function testInitialState() public view {
        assertEq(finance.totalSupply(), 200000000000);
        assertEq(finance.balances(address(finance)), 200000000000);
        assertFalse(finance.isSolved());
    }

    function testExploitSucceeds() public {
        console2.log("=== Before Exploit ===");
        console2.log("Test balance:", finance.balances(address(this)));
        console2.log("Exploit balance:", finance.balances(address(exploiter)));
        
        // Call exploit - msg.sender inside will be this test contract
        exploiter.exploit(address(finance));
        
        console2.log("\n=== After Exploit ===");
        console2.log("Test balance:", finance.balances(address(this)));
        console2.log("Exploit balance:", finance.balances(address(exploiter)));
        console2.log("Admin balance:", finance.balances(finance.admin()));
        console2.log("Burn balance:", finance.balances(finance.BurnAddr()));
        
        // The test contract should have received the referrer fees
        uint256 testBalance = finance.balances(address(this));
        assertGt(testBalance, 10000000, "Test balance not high enough");
    }

    function testCompleteChallenge() public {
        // Run the exploit
        exploiter.exploit(address(finance));
        
        uint256 balance = finance.balances(address(this));
        console2.log("Balance before setflag:", balance);
        
        // Call setflag from this address (which has the balance)
        finance.setflag();
        
        // Verify challenge is solved
        assertTrue(finance.isSolved(), "Challenge not solved");
    }
}
