// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {CrackMe} from "../src/contracts/CrackMe.sol";

contract ReverseEngineeringTest is Test {
    bytes32 internal constant SECRET = keccak256("EVMCtfCrackMeSecret");

    function testRevealByteLeakesFullKey() public {
        CrackMe target = new CrackMe(SECRET);
        bytes memory buffer = new bytes(16);
        for (uint8 i = 0; i < 16; ++i) {
            buffer[i] = target.revealByte(i);
        }
        bytes16 key;
        assembly {
            key := mload(add(buffer, 32))
        }
        assertEq(key, bytes16(SECRET));

        vm.expectRevert("index out of range");
        target.revealByte(16);
    }
}
