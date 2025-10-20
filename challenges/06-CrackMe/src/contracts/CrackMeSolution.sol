// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CrackMe} from "./CrackMe.sol";

/// @title High level solver for the CrackMe challenge
contract CrackMeSolution {
    CrackMe public immutable target;

    constructor(address _target) {
        target = CrackMe(_target);
    }

    function solve() external {
        bytes16 key = _recoverKey();
        uint64 checksum;
        unchecked {
            checksum = uint64(uint160(address(this))) + 1;
        }
        target.attempt(key, checksum);
    }

    function _recoverKey() internal view returns (bytes16 key) {
        bytes memory buffer = new bytes(16);
        for (uint8 i = 0; i < 16; ++i) {
            buffer[i] = target.revealByte(i);
        }
        assembly {
            key := mload(add(buffer, 32))
        }
    }
}
