// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../src/Casino.sol";

/**
 * @title CasinoEchidna
 * @notice Echidna harness that encodes the intended safety invariant
 */
contract CasinoEchidna {
    Casino internal immutable casino;

    constructor() {
        casino = new Casino();
    }

    /**
     * @notice Invariant: a player should never exceed one consecutive win
     * @dev Each call places exactly one bet using the publicly exposed RNG value.
     *      Echidna repeats calls, so on the second invocation consecutiveWins becomes 2
     *      and the property fails, demonstrating the bug without bespoke helper flows.
     */
    function echidna_no_double_win() public returns (bool) {
        uint256 guess = casino.getCurrentNumber();
        casino.bet(guess);

        uint256 nextGuess = casino.getCurrentNumber();
        casino.bet(nextGuess);

        return casino.consecutiveWins(address(this)) <= 1;
    }
}
