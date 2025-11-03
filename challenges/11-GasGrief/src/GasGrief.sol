// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GasGrief - Gas Griefing & DoS Attack Challenge
 * @dev This contract demonstrates gas griefing vulnerabilities where attackers can
 *      consume excessive gas to prevent normal operations, effectively creating
 *      a Denial of Service (DoS) attack.
 * 
 * VULNERABILITY: Unbounded gas consumption in loops and operations
 * ATTACK VECTOR: Submit large arrays or trigger expensive operations
 * IMPACT: Make contract unusable by consuming all available block gas
 * 
 * Educational Goals:
 * - Understand gas limits and block gas limits
 * - Learn about unbounded loop vulnerabilities
 * - Implement gas-efficient patterns
 * - Recognize DoS attack vectors
 */
contract GasGrief {
    
    // Events for tracking operations
    event RewardDistributed(address indexed recipient, uint256 amount, uint256 gasUsed);
    event BatchProcessed(uint256 count, uint256 totalGasUsed);
    event EmergencyStop(string reason, uint256 gasRemaining);
    event ChallengeCompleted(address indexed solver, string method);
    
    // State variables
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => bool) public isParticipant;
    address[] public participants;
    
    // Reward system
    uint256 public rewardPool = 1000 ether;
    uint256 public lastDistribution;
    bool public distributionInProgress;
    
    // Challenge tracking
    mapping(address => bool) public hasSolved;
    mapping(address => string) public solutionMethod;
    uint256 public totalSolvers;
    
    // Gas consumption tracking
    uint256 public maxGasUsed;
    uint256 public totalGasConsumed;
    mapping(address => uint256) public gasUsageByAddress;
    
    constructor() payable {
        owner = msg.sender;
        lastDistribution = block.timestamp;
    }
    
    /**
     * @dev Add participants to the reward system
     * VULNERABILITY: Unbounded loop - can consume excessive gas with large arrays
     */
    function addParticipants(address[] calldata newParticipants) external {
        require(msg.sender == owner, "Only owner can add participants");
        
        uint256 startGas = gasleft();
        
        // VULNERABLE: Unbounded loop - attacker can pass huge array
        for (uint256 i = 0; i < newParticipants.length; i++) {
            if (!isParticipant[newParticipants[i]]) {
                participants.push(newParticipants[i]);
                isParticipant[newParticipants[i]] = true;
                balances[newParticipants[i]] = 100; // Starting balance
            }
        }
        
        uint256 gasUsed = startGas - gasleft();
        gasUsageByAddress[msg.sender] += gasUsed;
        totalGasConsumed += gasUsed;
        
        if (gasUsed > maxGasUsed) {
            maxGasUsed = gasUsed;
        }
    }
    
    /**
     * @dev Distribute rewards to all participants
     * VULNERABILITY: Gas consumption grows linearly with participant count
     */
    function distributeRewards() external {
        require(msg.sender == owner, "Only owner can distribute");
        require(!distributionInProgress, "Distribution already in progress");
        require(participants.length > 0, "No participants");
        
        distributionInProgress = true;
        uint256 startGas = gasleft();
        
        uint256 rewardPerParticipant = rewardPool / participants.length;
        
        // VULNERABLE: Unbounded loop based on participants array
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            balances[participant] += rewardPerParticipant;
            
            uint256 gasUsedSoFar = startGas - gasleft();
            emit RewardDistributed(participant, rewardPerParticipant, gasUsedSoFar);
            
            // Check if we're consuming too much gas
            if (gasleft() < 10000) {
                emit EmergencyStop("Insufficient gas remaining", gasleft());
                distributionInProgress = false;
                return;
            }
        }
        
        uint256 totalGasUsed = startGas - gasleft();
        gasUsageByAddress[msg.sender] += totalGasUsed;
        totalGasConsumed += totalGasUsed;
        
        lastDistribution = block.timestamp;
        distributionInProgress = false;
        
        emit BatchProcessed(participants.length, totalGasUsed);
    }
    
    /**
     * @dev Process multiple operations in batch
     * VULNERABILITY: Nested loops create quadratic gas consumption
     */
    function batchProcessOperations(
        address[] calldata targets,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external {
        require(targets.length == amounts.length, "Array length mismatch");
        require(amounts.length == data.length, "Array length mismatch");
        
        uint256 startGas = gasleft();
        
        // VULNERABLE: Nested loops - O(n²) gas consumption
        for (uint256 i = 0; i < targets.length; i++) {
            for (uint256 j = 0; j < participants.length; j++) {
                if (participants[j] == targets[i]) {
                    balances[targets[i]] += amounts[i];
                    
                    // Simulate expensive operation
                    uint256 temp;
                    for (uint256 k = 0; k < amounts[i] && k < 100; k++) {
                        temp += k * amounts[i];
                    }
                }
            }
        }
        
        uint256 gasUsed = startGas - gasleft();
        gasUsageByAddress[msg.sender] += gasUsed;
        totalGasConsumed += gasUsed;
        
        if (gasUsed > maxGasUsed) {
            maxGasUsed = gasUsed;
        }
    }
    
    /**
     * @dev Expensive computation operation
     * VULNERABILITY: Unbounded computation based on user input
     */
    function computeExpensiveFunction(uint256 iterations) external view returns (uint256) {
        uint256 result = 1;
        
        // VULNERABLE: User controls iteration count - can consume all gas
        for (uint256 i = 0; i < iterations; i++) {
            result = (result * 7 + 13) % 1000000007; // Expensive modular arithmetic
            
            // Simulate more expensive operations
            if (i % 10 == 0) {
                result += uint256(keccak256(abi.encodePacked(result, block.timestamp, i))) & 0xFF;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Gas-optimized version of addParticipants (solution)
     */
    function addParticipantsOptimized(address[] calldata newParticipants) external {
        require(msg.sender == owner, "Only owner can add participants");
        require(newParticipants.length <= 50, "Too many participants at once"); // Gas limit
        
        uint256 startGas = gasleft();
        
        for (uint256 i = 0; i < newParticipants.length; i++) {
            if (!isParticipant[newParticipants[i]]) {
                participants.push(newParticipants[i]);
                isParticipant[newParticipants[i]] = true;
                balances[newParticipants[i]] = 100;
            }
            
            // Gas check to prevent DoS
            if (gasleft() < 20000) {
                break; // Stop if running low on gas
            }
        }
        
        uint256 gasUsed = startGas - gasleft();
        gasUsageByAddress[msg.sender] += gasUsed;
    }
    
    /**
     * @dev Paginated reward distribution (solution)
     */
    function distributeRewardsPaginated(uint256 startIndex, uint256 batchSize) external {
        require(msg.sender == owner, "Only owner can distribute");
        require(startIndex < participants.length, "Start index out of bounds");
        require(batchSize > 0 && batchSize <= 100, "Invalid batch size"); // Limit batch size
        
        uint256 endIndex = startIndex + batchSize;
        if (endIndex > participants.length) {
            endIndex = participants.length;
        }
        
        uint256 startGas = gasleft();
        uint256 rewardPerParticipant = rewardPool / participants.length;
        
        for (uint256 i = startIndex; i < endIndex; i++) {
            balances[participants[i]] += rewardPerParticipant;
        }
        
        uint256 gasUsed = startGas - gasleft();
        gasUsageByAddress[msg.sender] += gasUsed;
        
        emit BatchProcessed(endIndex - startIndex, gasUsed);
    }
    
    /**
     * @dev Check if gas griefing attack was successfully demonstrated
     */
    function checkSolution() external {
        require(!hasSolved[msg.sender], "Already solved");
        
        string memory method;
        
        // Check if they demonstrated gas griefing
        if (gasUsageByAddress[msg.sender] > 1000000) { // Used > 1M gas
            method = "Gas griefing attack demonstrated";
            hasSolved[msg.sender] = true;
        }
        // Check if they used optimized functions
        else if (gasUsageByAddress[msg.sender] > 0 && gasUsageByAddress[msg.sender] < 100000) {
            method = "Gas-optimized solution implemented";
            hasSolved[msg.sender] = true;
        }
        
        if (hasSolved[msg.sender]) {
            solutionMethod[msg.sender] = method;
            totalSolvers++;
            emit ChallengeCompleted(msg.sender, method);
        }
    }
    
    // Educational analysis functions
    
    function getParticipantCount() external view returns (uint256) {
        return participants.length;
    }
    
    function getGasAnalysis() external view returns (
        uint256 maxGasUsedInSingleTx,
        uint256 totalGasConsumedOverall,
        uint256 participantCount,
        uint256 estimatedGasForFullDistribution
    ) {
        return (
            maxGasUsed,
            totalGasConsumed,
            participants.length,
            participants.length * 50000 // Estimated gas per participant
        );
    }
    
    function simulateGasUsage(uint256 operationCount) external pure returns (uint256) {
        // Simulate gas cost calculation
        uint256 baseGas = 21000;
        uint256 gasPerOperation = 50000;
        return baseGas + (operationCount * gasPerOperation);
    }
    
    function getDoSVulnerabilityInfo() external view returns (
        string memory vulnerability,
        string memory impact,
        string memory mitigation
    ) {
        return (
            "Unbounded loops and user-controlled gas consumption",
            "DoS attack by consuming all available block gas",
            "Implement gas limits, pagination, and circuit breakers"
        );
    }
    
    // Emergency functions
    
    function emergencyReset() external {
        require(msg.sender == owner, "Only owner");
        delete participants;
        distributionInProgress = false;
    }
    
    function withdraw() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }
    
    // Receive function to accept donations to reward pool
    receive() external payable {
        rewardPool += msg.value;
    }
}