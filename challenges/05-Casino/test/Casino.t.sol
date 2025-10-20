// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Casino.sol";
import "../src/CasinoExploit.sol";
import "../src/CasinoAssemblyAttack.sol";

contract CasinoTest is Test {
    Casino public casino;
    CasinoExploit public exploit;
    CasinoAssemblyAttack public assemblyAttack;

    address public player;
    address public attacker;

    function setUp() public {
        casino = new Casino();

        player = makeAddr("player");
        attacker = makeAddr("attacker");

        vm.prank(attacker);
        exploit = new CasinoExploit(address(casino));

        vm.prank(attacker);
        assemblyAttack = new CasinoAssemblyAttack(address(casino));
    }

    function test_RandomNumberIsPredictable() public {
        bytes32 seed = casino.getSeed();
        uint256 expected = uint256(keccak256(abi.encodePacked(seed, block.number))) ^ 0x539;

        assertEq(expected, casino.getCurrentNumber());
    }

    function test_PlayerCanWinTwiceWithPrediction() public {
        uint256 prediction = uint256(keccak256(abi.encodePacked(casino.getSeed(), block.number))) ^ 0x539;

        vm.prank(attacker);
        casino.bet(prediction);
        vm.prank(attacker);
        casino.bet(prediction);

        assertEq(casino.consecutiveWins(attacker), 2);

        vm.prank(attacker);
        uint16[] memory result = casino.done();
        assertEq(result.length, 0);
    }

    function test_ExploitContractWinsTwice() public {
        vm.prank(attacker);
        exploit.winTwice();

        assertEq(casino.consecutiveWins(address(exploit)), 2);
        assertTrue(exploit.solved());

        vm.prank(address(exploit));
        uint16[] memory result = casino.done();
        assertEq(result.length, 0);
    }

    function test_AssemblyAttackWinsTwice() public {
        vm.prank(attacker);
        assemblyAttack.assemblyWin();

        assertEq(casino.consecutiveWins(address(assemblyAttack)), 2);

        vm.prank(address(assemblyAttack));
        uint16[] memory result = casino.done();
        assertEq(result.length, 0);
    }

    function test_LosingResetsConsecutiveWins() public {
        uint256 prediction = uint256(keccak256(abi.encodePacked(casino.getSeed(), block.number))) ^ 0x539;
        uint256 wrongGuess = prediction ^ 1;

        vm.prank(attacker);
        casino.bet(wrongGuess);
        assertEq(casino.consecutiveWins(attacker), 0);

        vm.prank(attacker);
        casino.bet(prediction);
        vm.prank(attacker);
        casino.bet(prediction);

        assertEq(casino.consecutiveWins(attacker), 2);
    }
}
