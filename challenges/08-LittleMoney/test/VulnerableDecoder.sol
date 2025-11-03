// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract VulnerableDecoder {
    event Decoded(address indexed param1);

    function executeOperations(bytes calldata operations) external {
        address param1;
        assembly {
            // Assumes operations[0:4] is function selector
            // Assumes operations[4:36] is first parameter
            param1 := shr(96, calldataload(add(operations.offset, 0x04)))
        }
        emit Decoded(param1);
    }
}
