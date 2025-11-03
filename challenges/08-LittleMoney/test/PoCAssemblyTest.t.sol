// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../standalone-tests/src/PoCAssemblyLoad.sol";
import "../../standalone-tests/src/UFarmBrutalizer.sol";

contract PoCAssemblyTest is Test, UFarmBrutalizer {
    PoCAssemblyLoad poc;

    function setUp() public { poc = new PoCAssemblyLoad(); }

    function test_selector_unmasked_vs_masked() public brutalizeMemory {
        bytes4 sel = bytes4(0xdeadbeef);
        bytes memory extra = hex"112233445566778899aabbcc";
        bytes memory calldataBytes = poc.buildCalldata(sel, extra);

        bytes32 raw = poc.extractSelectorUnmasked(calldataBytes);
        bytes4 masked = poc.extractSelectorMasked(calldataBytes);

        bytes32 expected32 = bytes32(bytes4(sel));
        assertTrue(raw != expected32, "raw should include extra non-zero bytes beyond selector");
        assertEq(masked, sel);
    }

    function test_v3_path_unmasked_vs_masked() public brutalizeMemory {
        address token0 = address(uint160(uint256(keccak256("token0"))));
        address token1 = address(uint160(uint256(keccak256("token1"))));
        uint24 fee = 3000;

        bytes memory path = poc.buildV3Path(token0, fee, token1);

        bytes32 raw = poc.extractAddressUnmasked(path);
        address masked = poc.extractAddressMasked(path);

        bytes32 expectedToken0_32 = bytes32(uint256(uint160(token0)));
        assertTrue(raw != expectedToken0_32, "unmasked mload contains adjacent bytes / garbage");
        assertEq(masked, token0);
    }

    function test_print_v3_path_hex() public brutalizeMemory {
        address token0 = address(0x1111111111111111111111111111111111111111);
        address token1 = address(0x2222222222222222222222222222222222222222);
        uint24 fee = 0x0500;
        bytes memory path = poc.buildV3Path(token0, fee, token1);
        emit log_bytes(path);
        assertTrue(path.length == 20 + 3 + 20);
    }

    function test_print_calldata_hex() public brutalizeMemory {
        bytes4 sel = bytes4(0x0502b1c5);
        bytes memory rest = hex"0000000000000000000000003333333333333333333333333333333333333333";
        bytes memory data = poc.buildCalldata(sel, rest);
        emit log_bytes(data);
        assertTrue(data.length >= 4);
    }

    function test_memory_layout_assumptions_violated() public {
        bool assumptionsViolated = _testMemoryLayoutAssumptions();
        emit log_named_uint("Memory layout assumptions violated:", assumptionsViolated ? 1 : 0);
        assertTrue(assumptionsViolated, "Memory layout assumptions should be violated with corrupted data");
    }
}
