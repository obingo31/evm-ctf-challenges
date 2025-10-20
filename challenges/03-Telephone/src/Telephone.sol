// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Telephone
 * @notice A vulnerable contract that demonstrates tx.origin vs msg.sender confusion
 * @dev The vulnerability lies in the changeOwner function which checks tx.origin != msg.sender
 * This allows an attacker to change ownership by calling through an intermediary contract
 */
contract Telephone {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Initialize the contract with the deployer as owner
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Change the owner of the contract
     * @param _owner The new owner address
     * @dev VULNERABILITY: Uses tx.origin instead of proper access control
     * The condition tx.origin != msg.sender can be exploited by calling through another contract
     */
    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            address previousOwner = owner;
            owner = _owner;
            emit OwnershipTransferred(previousOwner, _owner);
        }
    }

    /**
     * @notice Get the current owner
     * @return The owner address
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}