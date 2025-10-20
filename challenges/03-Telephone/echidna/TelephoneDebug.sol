// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../src/Telephone.sol";

/**
 * @title TelephoneDebug
 * @notice Debug contract to understand tx.origin vs msg.sender in Echidna
 */
contract TelephoneDebug {
    Telephone public telephone;
    address public lastTxOrigin;
    address public lastMsgSender;
    bool public lastCallSucceeded;
    
    constructor() {
        telephone = new Telephone();
    }
    
    /**
     * @notice Debug function to capture tx.origin and msg.sender
     */
    function debugCall(address newOwner) public {
        lastTxOrigin = tx.origin;
        lastMsgSender = msg.sender;
        
        address ownerBefore = telephone.owner();
        telephone.changeOwner(newOwner);
        address ownerAfter = telephone.owner();
        
        lastCallSucceeded = (ownerBefore != ownerAfter);
    }
    
    /**
     * @notice Property: Check if tx.origin equals msg.sender
     */
    function echidna_tx_origin_equals_msg_sender() public view returns (bool) {
        return lastTxOrigin == lastMsgSender;
    }
    
    /**
     * @notice Property: Owner should remain initial owner if tx.origin == msg.sender
     */
    function echidna_owner_unchanged_when_equal() public view returns (bool) {
        if (lastTxOrigin == lastMsgSender) {
            return !lastCallSucceeded;
        }
        return true; // Don't care if they're different
    }
}