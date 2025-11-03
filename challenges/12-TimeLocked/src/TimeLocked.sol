// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeLocked - Timestamp Manipulation & Timelock Bypass Vulnerability
 * @notice Educational contract demonstrating timestamp manipulation attacks
 * @dev This contract showcases multiple timestamp-related vulnerabilities:
 *      1. Direct block.timestamp comparisons for access control
 *      2. Timelock bypass through timestamp manipulation
 *      3. Governance delay exploitation
 *      4. Time-based random number generation flaws
 * 
 * FOR EDUCATIONAL PURPOSES ONLY - DO NOT USE IN PRODUCTION
 */
contract TimeLocked {
    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event VaultOpened(address indexed user, uint256 timestamp, uint256 amount);
    event TimelockSet(address indexed admin, uint256 delay, uint256 effectiveTime);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin, uint256 timestamp);
    event EmergencyWithdrawn(address indexed admin, uint256 amount, uint256 timestamp);
    event ProposalCreated(uint256 indexed id, address proposer, uint256 executeAfter);
    event ProposalExecuted(uint256 indexed id, address executor, uint256 timestamp);
    event TimeManipulationDetected(uint256 blockTimestamp, uint256 expectedRange);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public admin;
    address public pendingAdmin;
    
    // Timelock state
    uint256 public timeLockDelay;        // Time delay for admin actions (seconds)
    uint256 public adminChangeTime;      // When admin change becomes effective
    uint256 public emergencyDelayTime;   // When emergency functions unlock
    
    // Vault state  
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lockUntil;   // VULNERABLE: Direct timestamp comparison
    
    // Governance state
    struct Proposal {
        address proposer;
        bytes data;
        uint256 executeAfter;           // VULNERABLE: Timestamp-based execution
        bool executed;
        uint256 value;
    }
    
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    
    // Time-based randomness (VULNERABLE)
    uint256 public lastRandomSeed;
    mapping(address => uint256) public userSeeds;
    
    // Constants for different vulnerability demonstrations
    uint256 public constant VAULT_LOCK_DURATION = 1 days;
    uint256 public constant GOVERNANCE_DELAY = 2 days;  
    uint256 public constant EMERGENCY_DELAY = 7 days;
    uint256 public constant MIN_TIMELOCK_DELAY = 1 hours;
    uint256 public constant MAX_TIMELOCK_DELAY = 30 days;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier afterTimelock() {
        require(block.timestamp >= adminChangeTime, "Timelock not expired");
        _;
    }

    modifier validTimestamp(uint256 _timestamp) {
        require(_timestamp > 0, "Invalid timestamp");
        require(_timestamp <= type(uint256).max, "Timestamp overflow");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() payable {
        admin = msg.sender;
        timeLockDelay = GOVERNANCE_DELAY;
        adminChangeTime = block.timestamp + timeLockDelay;
        emergencyDelayTime = block.timestamp + EMERGENCY_DELAY;
        lastRandomSeed = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                        VULNERABLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit funds with time lock (VULNERABLE to timestamp manipulation)
     * @dev Direct comparison with block.timestamp can be manipulated by miners
     */
    function depositWithTimeLock() external payable {
        require(msg.value > 0, "Must send ETH");
        
        deposits[msg.sender] += msg.value;
        // VULNERABILITY: Direct timestamp arithmetic - miners can manipulate within ~15 seconds
        lockUntil[msg.sender] = block.timestamp + VAULT_LOCK_DURATION;
        
        emit VaultOpened(msg.sender, block.timestamp, msg.value);
    }

    /**
     * @notice Withdraw funds after timelock expires (VULNERABLE)
     * @dev Can be bypassed through timestamp manipulation
     */
    function withdrawFromVault() external {
        require(deposits[msg.sender] > 0, "No deposit");
        // VULNERABILITY: Direct timestamp comparison - susceptible to manipulation
        require(block.timestamp >= lockUntil[msg.sender], "Still locked");
        
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        lockUntil[msg.sender] = 0;
        
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit VaultOpened(msg.sender, block.timestamp, amount);
    }

    /**
     * @notice Create governance proposal (VULNERABLE to timestamp manipulation)
     * @dev Execution time based on manipulatable timestamp
     */
    function createProposal(bytes calldata _data) external payable returns (uint256) {
        uint256 proposalId = nextProposalId++;
        
        // VULNERABILITY: Future execution time calculated from manipulatable block.timestamp
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            data: _data,
            executeAfter: block.timestamp + GOVERNANCE_DELAY,
            executed: false,
            value: msg.value
        });
        
        emit ProposalCreated(proposalId, msg.sender, proposals[proposalId].executeAfter);
        return proposalId;
    }

    /**
     * @notice Execute proposal after delay (VULNERABLE)
     * @dev Can be executed early through timestamp manipulation
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal doesn't exist");
        require(!proposal.executed, "Already executed");
        
        // VULNERABILITY: Direct timestamp comparison allows early execution
        require(block.timestamp >= proposal.executeAfter, "Too early");
        
        proposal.executed = true;
        
        // Execute the proposal data
        (bool success,) = address(this).call{value: proposal.value}(proposal.data);
        require(success, "Proposal execution failed");
        
        emit ProposalExecuted(_proposalId, msg.sender, block.timestamp);
    }

    /**
     * @notice Change admin with timelock (VULNERABLE)
     * @dev Timelock can be bypassed through timestamp manipulation
     */
    function changeAdmin(address _newAdmin) external onlyAdmin afterTimelock {
        require(_newAdmin != address(0), "Invalid admin");
        
        address oldAdmin = admin;
        admin = _newAdmin;
        pendingAdmin = address(0);
        
        // Reset timelock for next change
        adminChangeTime = block.timestamp + timeLockDelay;
        
        emit AdminChanged(oldAdmin, _newAdmin, block.timestamp);
    }

    /**
     * @notice Emergency withdrawal (VULNERABLE to early execution)
     * @dev Emergency delay can be bypassed
     */
    function emergencyWithdraw() external onlyAdmin {
        // VULNERABILITY: Direct timestamp comparison for emergency delay
        require(block.timestamp >= emergencyDelayTime, "Emergency delay not met");
        
        uint256 balance = address(this).balance;
        emergencyDelayTime = block.timestamp + EMERGENCY_DELAY; // Reset delay
        
        (bool success,) = admin.call{value: balance}("");
        require(success, "Emergency withdrawal failed");
        
        emit EmergencyWithdrawn(admin, balance, block.timestamp);
    }

    /**
     * @notice Generate pseudo-random number (VULNERABLE)
     * @dev Uses timestamp for randomness - predictable and manipulatable
     */
    function generateRandomSeed() external returns (uint256) {
        // VULNERABILITY: Timestamp-based randomness is predictable
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,           // Manipulatable by miners
            block.difficulty,          // Deprecated, returns prevrandao
            msg.sender,
            lastRandomSeed
        )));
        
        lastRandomSeed = seed;
        userSeeds[msg.sender] = seed;
        
        return seed;
    }

    /**
     * @notice Time-sensitive lottery (VULNERABLE)
     * @dev Winner determined by timestamp manipulation
     */
    function timeLottery() external payable returns (bool won) {
        require(msg.value >= 0.1 ether, "Minimum bet 0.1 ETH");
        
        // VULNERABILITY: Lottery outcome depends on manipulatable timestamp
        uint256 randomness = block.timestamp % 100;
        
        if (randomness < 10) { // 10% win chance
            // Winner gets double their bet
            uint256 winnings = msg.value * 2;
            
            if (address(this).balance >= winnings) {
                (bool success,) = msg.sender.call{value: winnings}("");
                require(success, "Payout failed");
                return true;
            }
        }
        
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                        MITIGATION EXAMPLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Secure time-based function using block ranges
     * @dev Uses block.number instead of timestamp for less manipulation
     */
    function secureTimeLock(uint256 _blocks) external view returns (bool unlocked) {
        // MITIGATION: Use block.number with reasonable ranges
        // Blocks are harder to manipulate than timestamps
        uint256 unlockBlock = block.number + _blocks;
        return block.number >= unlockBlock;
    }

    /**
     * @notice Secure random using commit-reveal scheme
     * @dev Two-phase randomness to prevent manipulation
     */
    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public commitBlocks;
    
    function commitRandom(bytes32 _commitment) external {
        commitments[msg.sender] = _commitment;
        commitBlocks[msg.sender] = block.number;
    }
    
    function revealRandom(uint256 _nonce) external returns (uint256) {
        require(commitments[msg.sender] != bytes32(0), "No commitment");
        require(block.number > commitBlocks[msg.sender] + 1, "Too early");
        require(block.number <= commitBlocks[msg.sender] + 255, "Too late");
        
        bytes32 hash = keccak256(abi.encodePacked(_nonce, msg.sender));
        require(hash == commitments[msg.sender], "Invalid reveal");
        
        // Clean up
        commitments[msg.sender] = bytes32(0);
        
        // Generate randomness using future block hash
        return uint256(blockhash(commitBlocks[msg.sender] + 1));
    }

    /*//////////////////////////////////////////////////////////////
                        ANALYSIS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Analyze timestamp manipulation potential
     */
    function analyzeTimestampRisk(uint256 _targetTime) external view returns (
        bool canManipulate,
        uint256 currentTime,
        int256 timeDiff,
        string memory risk
    ) {
        currentTime = block.timestamp;
        timeDiff = int256(_targetTime) - int256(currentTime);
        
        // Miners can manipulate timestamp by ~15 seconds
        if (timeDiff <= 15 && timeDiff >= -15) {
            canManipulate = true;
            risk = "HIGH - Within miner manipulation range";
        } else if (timeDiff <= 900) { // 15 minutes
            canManipulate = false;
            risk = "MEDIUM - Short timeframe, consider block.number";
        } else {
            canManipulate = false;
            risk = "LOW - Long timeframe, timestamp acceptable";
        }
    }

    /**
     * @notice Get comprehensive contract state
     */
    function getContractState() external view returns (
        uint256 currentTimestamp,
        uint256 contractBalance,
        uint256 totalProposals,
        uint256 nextAdminChange,
        uint256 nextEmergencyWindow
    ) {
        return (
            block.timestamp,
            address(this).balance,
            nextProposalId,
            adminChangeTime,
            emergencyDelayTime
        );
    }

    /**
     * @notice Check if timelock bypass is possible
     */
    function checkTimelockBypass() external view returns (bool bypassPossible, string memory reason) {
        uint256 timeToUnlock = adminChangeTime > block.timestamp ? 
            adminChangeTime - block.timestamp : 0;
            
        if (timeToUnlock <= 15) {
            return (true, "Timelock can be bypassed via timestamp manipulation");
        } else if (timeToUnlock <= 900) {
            return (false, "Consider using block.number for better security");
        } else {
            return (false, "Timelock is reasonably secure");
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get user deposit info
     */
    function getUserDepositInfo(address _user) external view returns (
        uint256 depositAmount,
        uint256 unlockTime,
        bool canWithdraw,
        uint256 timeRemaining
    ) {
        depositAmount = deposits[_user];
        unlockTime = lockUntil[_user];
        canWithdraw = block.timestamp >= unlockTime;
        timeRemaining = unlockTime > block.timestamp ? unlockTime - block.timestamp : 0;
    }

    /**
     * @notice Get proposal details
     */
    function getProposal(uint256 _id) external view returns (
        address proposer,
        bytes memory data,
        uint256 executeAfter,
        bool executed,
        uint256 value,
        bool canExecute
    ) {
        Proposal storage proposal = proposals[_id];
        return (
            proposal.proposer,
            proposal.data,
            proposal.executeAfter,
            proposal.executed,
            proposal.value,
            block.timestamp >= proposal.executeAfter && !proposal.executed
        );
    }

    /*//////////////////////////////////////////////////////////////
                        CHALLENGE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Complete challenge by exploiting timestamp vulnerabilities
     * @dev Players must demonstrate multiple timestamp attacks
     */
    function completeChallenge() external view returns (bool success, string memory message) {
        // Check if user has exploited multiple vulnerabilities
        bool hasDeposit = deposits[msg.sender] > 0;
        bool hasProposal = false;
        bool hasRandomSeed = userSeeds[msg.sender] > 0;
        
        // Check if user created any proposals
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (proposals[i].proposer == msg.sender) {
                hasProposal = true;
                break;
            }
        }
        
        if (hasDeposit && hasProposal && hasRandomSeed) {
            return (true, "Challenge completed! You've demonstrated timestamp manipulation vulnerabilities.");
        }
        
        return (false, "Demonstrate timestamp attacks: deposit, create proposal, and generate random seed");
    }

    /*//////////////////////////////////////////////////////////////
                            FALLBACK
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        // Accept ETH for testing purposes
    }
    
    fallback() external payable {
        // Handle unexpected calls
        revert("Function not found");
    }
}