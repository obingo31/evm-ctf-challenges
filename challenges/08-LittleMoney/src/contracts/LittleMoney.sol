// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title LittleMoney Challenge
/// @notice Pay just 1 wei to emit the SendFlag event
contract LittleMoney {
    event SendFlag(address indexed sender);

    mapping(address => bool) private owners;

    modifier onlyOwner() {
        require(owners[msg.sender], "not owner");
        _;
    }

    modifier checkPermission(address addr) {
        _;
        permission(addr);
    }

    constructor() {
        owners[msg.sender] = true;
    }

    /// @notice Emit SendFlag event if exactly 1 wei is sent
    function payforflag() public payable onlyOwner {
        require(msg.value == 1, "I only need a little money!");
        emit SendFlag(msg.sender);
    }

    /// @notice Execute a delegatecall on target with special permission checks
    /// @dev The delegatecall must revert and return (blockNumber, value)
    /// @dev Then manipulates function pointer and calls it
    function execute(address target) external checkPermission(target) {
        // Execute delegatecall that must revert
        (bool success, ) = target.delegatecall(abi.encode(bytes4(keccak256("func()"))));
        require(!success, "no cover!");

        // Extract return data
        uint256 b;
        uint256 v;
        (b, v) = getReturnData();
        require(b == block.number);

        // Create function struct and manipulate pointer
        func memory set;
        set.ptr = renounce;
        uint x;
        assembly {
            x := mload(set)
            mstore(set, add(mload(set), v))
        }
        // Call the manipulated function pointer
        set.ptr();
    }

    /// @notice Extract return data from reverted delegatecall
    function getReturnData() internal pure returns (uint256, uint256) {
        uint256 returnSize;
        uint256 returnData;
        assembly {
            returnSize := returndatasize()
            if gt(returnSize, 0) {
                returndatacopy(0, 0, returnSize)
                returnData := mload(0)
            }
        }
        // First 256 bits contain both values (packed)
        uint256 b = returnData >> 128;
        uint256 v = returnData & 0xffffffff;
        return (b, v);
    }

    /// @notice Dummy function to be renounced (serves as function pointer anchor)
    function renounce() internal {
        // This function is never actually called directly
        // Its JUMPDEST is used as a starting point for pointer arithmetic
    }

    /// @notice Check if address has valid bytecode size and caller is the target
    function permission(address addr) internal view {
        bool con = calcCode(addr);
        require(con, "permission");
        require(msg.sender == addr);
    }

    /// @notice Verify bytecode size is between 1 and 12 bytes
    function calcCode(address addr) internal view returns (bool) {
        uint256 x;
        assembly {
            x := extcodesize(addr)
        }
        if (x == 0) {
            return false;
        } else if (x > 12) {
            return false;
        } else {
            assembly {
                return(0x20, 0x00)
            }
        }
    }
}

/// @notice Function pointer struct for assembly manipulation
struct func {
    function() internal ptr;
}
