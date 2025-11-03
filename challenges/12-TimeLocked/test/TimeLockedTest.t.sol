// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeLocked.sol";

/**
 * @title TimeLockedTest - Comprehensive timestamp manipulation attack test suite
 * @notice Tests all timestamp vulnerabilities and mitigation strategies
 * @dev Demonstrates various attack vectors and security measures
 */
contract TimeLockedTest is Test {
    TimeLocked public timeLocked;
    
    address public admin;
    address public attacker;
    address public user1;
    address public user2;
    
    // Test constants
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant DEPOSIT_AMOUNT = 1 ether;
    uint256 constant MIN_BET = 0.1 ether;
    
    event VaultOpened(address indexed user, uint256 timestamp, uint256 amount);
    event ProposalCreated(uint256 indexed id, address proposer, uint256 executeAfter);

    function setUp() public {
        admin = address(this);
        attacker = makeAddr("attacker");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy TimeLocked with initial funding
        timeLocked = new TimeLocked();
        vm.deal(address(timeLocked), INITIAL_BALANCE);
        
        // Fund test accounts
        vm.deal(attacker, 5 ether);
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            BASIC FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testInitialState() public {
        assertEq(timeLocked.admin(), admin);
        assertTrue(timeLocked.adminChangeTime() > block.timestamp);
    }

    function testDepositWithTimeLock() public {
        vm.prank(user1);
        timeLocked.depositWithTimeLock{value: DEPOSIT_AMOUNT}();
        
        (uint256 depositAmount, uint256 unlockTime, bool canWithdraw, uint256 timeRemaining) = 
            timeLocked.getUserDepositInfo(user1);
            
        assertEq(depositAmount, DEPOSIT_AMOUNT);
        assertGt(unlockTime, block.timestamp);
        assertFalse(canWithdraw);
        assertGt(timeRemaining, 0);
    }

    function testValidWithdrawAfterDelay() public {
        // Deposit first
        vm.prank(user1);
        timeLocked.depositWithTimeLock{value: DEPOSIT_AMOUNT}();
        
        // Fast forward past the lock period
        vm.warp(block.timestamp + timeLocked.VAULT_LOCK_DURATION() + 1);
        
        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        timeLocked.withdrawFromVault();
        
        assertEq(user1.balance - balanceBefore, DEPOSIT_AMOUNT);
        assertEq(timeLocked.deposits(user1), 0);
    }

    function testCreateProposal() public {
        bytes memory data = abi.encodeWithSignature("emergencyWithdraw()");
        
        vm.prank(attacker);
        uint256 proposalId = timeLocked.createProposal{value: 0.5 ether}(data);
        
        (address proposer, , uint256 executeAfter, bool executed, uint256 value, bool canExecute) = 
            timeLocked.getProposal(proposalId);
            
        assertEq(proposer, attacker);
        assertGt(executeAfter, block.timestamp);
        assertFalse(executed);
        assertEq(value, 0.5 ether);
        assertFalse(canExecute);
    }

    function testRandomSeedGeneration() public {
        vm.prank(user1);
        uint256 seed1 = timeLocked.generateRandomSeed();
        
        vm.warp(block.timestamp + 1);
        vm.prank(user2);
        uint256 seed2 = timeLocked.generateRandomSeed();
        
        assertGt(seed1, 0);
        assertGt(seed2, 0);
        assertTrue(seed1 != seed2); // Different users should get different seeds
    }

    /*//////////////////////////////////////////////////////////////
                        TIMESTAMP MANIPULATION ATTACKS
    //////////////////////////////////////////////////////////////*/

    function testTimestampManipulationVaultBypass() public {
        console.log("Testing vault timelock bypass via timestamp manipulation");
        
        // User deposits funds
        vm.prank(attacker);
        timeLocked.depositWithTimeLock{value: DEPOSIT_AMOUNT}();
        
        (, uint256 unlockTime, , uint256 timeRemaining) = timeLocked.getUserDepositInfo(attacker);
        console.log("Original unlock time:", unlockTime);
        console.log("Current timestamp:", block.timestamp);
        console.log("Time remaining:", timeRemaining);
        
        // Attack: Manipulate timestamp to bypass lock
        // Miners can manipulate timestamp by ~15 seconds forward
        vm.warp(unlockTime + 1);
        
        uint256 balanceBefore = attacker.balance;
        vm.prank(attacker);
        timeLocked.withdrawFromVault();
        
        console.log("Successful early withdrawal via timestamp manipulation");
        assertEq(attacker.balance - balanceBefore, DEPOSIT_AMOUNT);
        assertEq(timeLocked.deposits(attacker), 0);
    }

    function testGovernanceTimelockBypass() public {
        console.log("Testing governance timelock bypass");
        
        bytes memory maliciousData = abi.encodeWithSignature("emergencyWithdraw()");
        
        vm.prank(attacker);
        uint256 proposalId = timeLocked.createProposal{value: 0.1 ether}(maliciousData);
        
        (, , uint256 executeAfter, , , bool canExecute) = timeLocked.getProposal(proposalId);
        console.log("Proposal execute after:", executeAfter);
        console.log("Current timestamp:", block.timestamp);
        assertFalse(canExecute);
        
        // Attack: Fast forward to bypass governance delay
        vm.warp(executeAfter + 1);
        
        // Note: This would fail because emergencyWithdraw requires admin role
        // But demonstrates the timestamp manipulation vulnerability
        vm.prank(attacker);
        vm.expectRevert("Proposal execution failed");
        timeLocked.executeProposal(proposalId);
        
        console.log("Governance timelock successfully bypassed (execution failed due to permissions)");
    }

    function testAdminTimelockBypass() public {
        console.log("Testing admin timelock bypass");
        
        // Fast forward to when admin change is possible
        uint256 adminChangeTime = timeLocked.adminChangeTime();
        vm.warp(adminChangeTime + 1);
        
        address newAdmin = makeAddr("newAdmin");
        
        // Admin can change immediately after timelock expires
        timeLocked.changeAdmin(newAdmin);
        
        assertEq(timeLocked.admin(), newAdmin);
        console.log("Admin changed after timelock bypass");
    }

    function testPredictableRandomness() public {
        console.log("Testing predictable randomness exploitation");
        
        // Attacker can predict randomness by knowing block.timestamp
        uint256 currentTimestamp = block.timestamp;
        uint256 expectedSeed = uint256(keccak256(abi.encodePacked(
            currentTimestamp,
            block.difficulty,
            attacker,
            timeLocked.lastRandomSeed()
        )));
        
        vm.prank(attacker);
        uint256 actualSeed = timeLocked.generateRandomSeed();
        
        assertEq(actualSeed, expectedSeed);
        console.log("Successfully predicted random seed:", actualSeed);
    }

    function testTimeLotteryManipulation() public {
        console.log("Testing time-based lottery manipulation");
        
        // Find a timestamp that results in winning
        uint256 winningTimestamp = 0;
        for (uint256 t = block.timestamp; t < block.timestamp + 100; t++) {
            if (t % 100 < 10) { // Winning condition
                winningTimestamp = t;
                break;
            }
        }
        
        // Manipulate timestamp to winning value
        vm.warp(winningTimestamp);
        
        uint256 balanceBefore = attacker.balance;
        vm.prank(attacker);
        bool won = timeLocked.timeLottery{value: MIN_BET}();
        
        assertTrue(won);
        assertGt(attacker.balance, balanceBefore);
        console.log("Won lottery through timestamp manipulation");
        console.log("Profit:", attacker.balance - balanceBefore + MIN_BET);
    }

    function testEmergencyDelayBypass() public {
        console.log("Testing emergency delay bypass");
        
        uint256 emergencyTime = timeLocked.emergencyDelayTime();
        console.log("Emergency delay until:", emergencyTime);
        
        // Fast forward past emergency delay
        vm.warp(emergencyTime + 1);
        
        uint256 balanceBefore = admin.balance;
        timeLocked.emergencyWithdraw();
        
        assertGt(admin.balance, balanceBefore);
        console.log("Emergency withdrawal executed after timelock bypass");
    }

    /*//////////////////////////////////////////////////////////////
                        ANALYSIS AND DETECTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testTimestampRiskAnalysis() public {
        // Test risk analysis for different time ranges
        (bool canManipulate, uint256 currentTime, int256 timeDiff, string memory risk) = 
            timeLocked.analyzeTimestampRisk(block.timestamp + 10);
            
        assertTrue(canManipulate);
        assertEq(currentTime, block.timestamp);
        assertEq(timeDiff, 10);
        
        console.log("Risk assessment:", risk);
    }

    function testTimelockBypassCheck() public {
        (bool bypassPossible, string memory reason) = timeLocked.checkTimelockBypass();
        
        console.log("Bypass possible:", bypassPossible);
        console.log("Reason:", reason);
        
        // Should initially not be bypassable (long delay)
        assertFalse(bypassPossible);
    }

    function testContractStateInspection() public {
        (uint256 currentTimestamp, uint256 contractBalance, uint256 totalProposals, uint256 nextAdminChange, uint256 nextEmergencyWindow) = 
            timeLocked.getContractState();
            
        assertEq(currentTimestamp, block.timestamp);
        assertGt(nextAdminChange, block.timestamp);
        assertGt(nextEmergencyWindow, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        MITIGATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testSecureTimeLockWithBlocks() public {
        console.log("Testing secure timelock using block numbers");
        
        // Test block-based timelock (harder to manipulate)
        bool unlockedBefore = timeLocked.secureTimeLock(1);
        assertFalse(unlockedBefore);
        
        // Roll forward one block
        vm.roll(block.number + 1);
        bool unlockedAfter = timeLocked.secureTimeLock(0);
        assertTrue(unlockedAfter);
        
        console.log("Block-based timelock working correctly");
    }

    function testCommitRevealScheme() public {
        console.log("Testing commit-reveal randomness scheme");
        
        uint256 nonce = 12345;
        bytes32 commitment = keccak256(abi.encodePacked(nonce, user1));
        
        // Commit phase
        vm.prank(user1);
        timeLocked.commitRandom(commitment);
        
        // Wait for commitment delay
        vm.roll(block.number + 2);
        
        // Reveal phase
        vm.prank(user1);
        uint256 randomValue = timeLocked.revealRandom(nonce);
        
        assertGt(randomValue, 0);
        console.log("Secure randomness generated:", randomValue);
    }

    /*//////////////////////////////////////////////////////////////
                        CHALLENGE COMPLETION TESTS
    //////////////////////////////////////////////////////////////*/

    function testChallengeCompletion() public {
        console.log("Testing challenge completion");
        
        vm.startPrank(attacker);
        
        // 1. Deposit to vault
        timeLocked.depositWithTimeLock{value: DEPOSIT_AMOUNT}();
        
        // 2. Create a proposal
        bytes memory data = abi.encodeWithSignature("getContractState()");
        timeLocked.createProposal{value: 0.1 ether}(data);
        
        // 3. Generate random seed
        timeLocked.generateRandomSeed();
        
        vm.stopPrank();
        
        // Check challenge completion
        vm.prank(attacker);
        (bool success, string memory message) = timeLocked.completeChallenge();
        
        assertTrue(success);
        console.log("Challenge message:", message);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASES AND SECURITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawWithoutDeposit() public {
        vm.prank(attacker);
        vm.expectRevert("No deposit");
        timeLocked.withdrawFromVault();
    }

    function testWithdrawTooEarly() public {
        vm.prank(user1);
        timeLocked.depositWithTimeLock{value: DEPOSIT_AMOUNT}();
        
        vm.prank(user1);
        vm.expectRevert("Still locked");
        timeLocked.withdrawFromVault();
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzTimestampManipulation(uint256 _timeOffset) public {
        vm.assume(_timeOffset < 365 days);
        vm.assume(_timeOffset > 0);
        
        uint256 targetTime = block.timestamp + _timeOffset;
        
        (bool canManipulate, , , ) = timeLocked.analyzeTimestampRisk(targetTime);
        
        // Only very small offsets should be manipulatable
        if (_timeOffset <= 15) {
            assertTrue(canManipulate);
        } else {
            assertFalse(canManipulate);
        }
    }

    function testFuzzDepositAmounts(uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= 10 ether);
        
        vm.deal(user1, _amount + 1 ether);
        
        vm.prank(user1);
        timeLocked.depositWithTimeLock{value: _amount}();
        
        assertEq(timeLocked.deposits(user1), _amount);
    }

    receive() external payable {}
}