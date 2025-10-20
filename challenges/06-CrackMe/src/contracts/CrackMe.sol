// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title CrackMe challenge contract
/// @notice Stores a secret and exposes a flawed reveal API that allows reconstructing the key
contract CrackMe {
    error InvalidKey();
    error InvalidChecksum();
    error AlreadySolved();

    bytes32 private immutable secret;
    address public solver;
    bool public solved;
    uint64 public nonce;

    constructor(bytes32 _secret) {
        secret = _secret;
    }

    /// @notice Attempt to solve the challenge using a reconstructed key and checksum
    function attempt(bytes16 key, uint64 checksum) external {
        if (solved) revert AlreadySolved();
        if (key != bytes16(secret)) revert InvalidKey();

        unchecked {
            nonce += 1;
        }

        uint64 expected = uint64(uint160(msg.sender)) + nonce;
        if (checksum != expected) revert InvalidChecksum();

        solver = msg.sender;
        solved = true;
    }

    /// @notice Leak a byte of the secret key at the provided index
    function revealByte(uint8 index) external view returns (bytes1 b) {
        require(index < 16, "index out of range");
        bytes memory encoded = abi.encodePacked(bytes16(secret));
        return encoded[index];
    }

    /// @notice Expose the full secret (available once the puzzle is solved)
    function rawSecret() external view returns (bytes32) {
        return secret;
    }
}
