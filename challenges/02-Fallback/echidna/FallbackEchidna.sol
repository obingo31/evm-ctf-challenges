// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../src/Fallback.sol";

/**
 * @title FallbackEchidna
 * @notice Echidna harness that demonstrates the Fallback ownership bug
 * @dev Inherits the vulnerable contract so fuzzed calls exercise the real logic
 */
contract FallbackEchidna is Fallback {
    address internal immutable originalOwner;

    constructor() payable {
        originalOwner = owner;
    }

    /**
     * @notice Property: the original deployer must always remain owner
     * @dev Echidna will find a counterexample by contributing and then triggering the receive path
     */
    function echidna_owner_never_changes() public view returns (bool) {
        return owner == originalOwner;
    }

    /**
     * @notice Helper that mirrors the vulnerable receive logic with explicit call
     * @dev Allows Echidna to drive the ownership change using standard function invocation
     */
    function echidna_owner_has_1000eth() public view returns (bool) {
        if (owner != originalOwner) {
            return contributions[owner] > 1000 ether;
        }
        return true;
    }

    /**
     * @notice Property: owner should never be zero address
     * @dev Basic sanity check
     * Expected: PASS
     */
    function echidna_owner_not_zero() public view returns (bool) {
        return owner != address(0);
    }

    /**
     * @notice Property: owner must have made a contribution
     * @dev If owner changed, they must have contributed something
     * Expected: Could PASS or FAIL depending on attack path
     */
    function echidna_owner_has_contribution() public view returns (bool) {
        return contributions[owner] > 0;
    }
}
