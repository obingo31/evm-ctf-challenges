// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Casino
 * @notice Vulnerable casino contract with predictable randomness
 * @dev DO NOT USE IN PRODUCTION - Contains critical RNG vulnerability
 */
contract Casino {
    bytes32 private seed;
    mapping(address => uint256) public consecutiveWins;

    event BetPlaced(address indexed player, uint256 guess, uint256 result, bool won);
    event ConsecutiveWinsUpdated(address indexed player, uint256 wins);

    constructor() {
        seed = keccak256("satoshi nakmoto");
    }

    /**
     * @notice Place a bet
     * @param guess The player's guess
     *
     * VULNERABILITY EXPLANATION:
     * The "random" number is calculated as:
     *   num = keccak256(seed, block.number) ^ 0x539
     *
     * Problem: block.number is PUBLIC information!
     * - Anyone can read it
     * - Anyone can calculate the same "random" number
     * - Attackers can always win!
     */
    function bet(uint256 guess) public {
        // Generate "random" number
        uint256 num = uint256(keccak256(abi.encodePacked(seed, block.number))) ^ 0x539;

        bool won = (guess == num);

        if (won) {
            consecutiveWins[msg.sender] = consecutiveWins[msg.sender] + 1;
        } else {
            consecutiveWins[msg.sender] = 0;
        }

        emit BetPlaced(msg.sender, guess, num, won);
        emit ConsecutiveWinsUpdated(msg.sender, consecutiveWins[msg.sender]);
    }

    /**
     * @notice Check if player has won enough times
     * @return Empty array if player has won more than once
     */
    function done() public view returns (uint16[] memory) {
        if (consecutiveWins[msg.sender] > 1) {
            return new uint16[](0);
        }
        // Return something if not done
        uint16[] memory notDone = new uint16[](1);
        notDone[0] = 1;
        return notDone;
    }

    /**
     * @notice Get seed (for testing purposes)
     * @dev In production, this would be truly private, but it ultimately
     *      does not matter because block.number is public and contract
     *      storage can always be read on-chain.
     */
    function getSeed() public view returns (bytes32) {
        return seed;
    }

    /**
     * @notice Calculate the "random" number for current block
     * @dev Exposes the vulnerability - anyone can call this!
     */
    function getCurrentNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, block.number))) ^ 0x539;
    }
}
