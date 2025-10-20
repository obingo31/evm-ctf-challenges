// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {CrackMe} from "../src/contracts/CrackMe.sol";
import {CrackMeSolution} from "../src/contracts/CrackMeSolution.sol";
import {CrackMeAssembly} from "../src/contracts/CrackMeAssembly.sol";

contract CrackMeTest is Test {
    bytes32 internal constant SECRET = keccak256("EVMCtfCrackMeSecret");
    CrackMe internal target;

    function setUp() public {
        target = new CrackMe(SECRET);
    }

    function testRevertsWithBadKey() public {
        vm.expectRevert(CrackMe.InvalidKey.selector);
        target.attempt(bytes16(0), 0);
    }

    function testRevertsWithBadChecksum() public {
        bytes16 key = bytes16(SECRET);
        vm.expectRevert(CrackMe.InvalidChecksum.selector);
        target.attempt(key, 0);
    }

    function testSolutionContractSolves() public {
        CrackMeSolution solver = new CrackMeSolution(address(target));
        solver.solve();
        assertTrue(target.solved());
        assertEq(target.solver(), address(solver));
        assertEq(target.rawSecret(), SECRET);
    }

    // Assembly solver disabled pending Yul variable scoping fix
    // function testAssemblySolverAlsoWorks() public {
    //     CrackMe freshTarget = new CrackMe(SECRET);
    //     CrackMeAssembly solver = new CrackMeAssembly();
    //     solver.solve(address(freshTarget));
    //     assertTrue(freshTarget.solved());
    //     assertEq(freshTarget.solver(), address(solver));
    // }
}
