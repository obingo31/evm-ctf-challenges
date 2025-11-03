// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "./VulnerableDecoder.sol";

contract VulnerableDecoderTest is Test {
    VulnerableDecoder decoder;

    function setUp() public {
        decoder = new VulnerableDecoder();
    }

    function testNormalOperation() public {
        // Standard encoding: selector + address
        bytes memory data = abi.encodeWithSelector(
            bytes4(0x12345678),
            address(0x1111111111111111111111111111111111111111)
        );
        vm.expectEmit(true, false, false, false);
        emit VulnerableDecoder.Decoded(0x1111111111111111111111111111111111111111);
        decoder.executeOperations(data);
    }

    function testCalldataInjection() public {
        // Craft calldata with overlapping fields
        // selector: 0x12345678
        // param1: 0x2222222222222222222222222222222222222222
        // But inject attacker address at offset 4
        bytes memory data = new bytes(36);
        // selector
        data[0] = 0x12;
        data[1] = 0x34;
        data[2] = 0x56;
        data[3] = 0x78;
        // attacker address at offset 4
        for (uint i = 0; i < 20; i++) {
            data[4 + i] = bytes1(uint8(uint160(0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef) >> (8 * (19 - i))));
        }
        // fill rest with zeros
        for (uint i = 24; i < 36; i++) {
            data[i] = 0x00;
        }
        vm.expectEmit(true, false, false, false);
        emit VulnerableDecoder.Decoded(0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef);
        decoder.executeOperations(data);
    }
}
