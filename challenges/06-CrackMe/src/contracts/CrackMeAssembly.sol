// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CrackMe} from "./CrackMe.sol";

/// @title Assembly-powered solver for CrackMe
contract CrackMeAssembly {
    function solve(address target) external {
        bytes16 key = recoverKey(target);
        uint64 checksum = uint64(uint160(address(this))) + 1;
        address crackMeAddress = target;

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(224, 0x6400ac42))
            mstore(add(ptr, 0x04), shl(128, key))
            mstore(add(ptr, 0x24), checksum)

            let success := call(gas(), crackMeAddress, 0, ptr, 0x44, 0, 0)
            if iszero(success) { revert(0, 0) }

            mstore(0x40, add(ptr, 0x60))
        }
    }

    function recoverKey(address target) public view returns (bytes16 key) {
        assembly {
            let ptr := mload(0x40)
            let calldataPtr := ptr
            let outputPtr := add(ptr, 0x40)
            let bufferPtr := add(ptr, 0x80)
            mstore(bufferPtr, 0)

            for { let i := 0 } lt(i, 16) { i := add(i, 1) } {
                mstore(calldataPtr, shl(224, 0xcd5f77b0))
                mstore(add(calldataPtr, 0x04), 0)
                mstore8(add(calldataPtr, 0x23), i)

                if iszero(staticcall(gas(), target, calldataPtr, 0x24, outputPtr, 0x20)) {
                    revert(0, 0)
                }

                let b := byte(31, mload(outputPtr))
                mstore8(add(bufferPtr, i), b)
            }

            key := mload(bufferPtr)
            mstore(0x40, add(bufferPtr, 0x20))
        }
    }
}
