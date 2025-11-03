// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TimeLocked.sol";

/**
 * @title Deploy TimeLocked Challenge
 * @notice Deployment script for TimeLocked timestamp manipulation challenge
 * @dev Sets up the contract with initial funding for educational purposes
 */
contract Deploy is Script {
    function run() external returns (TimeLocked timeLocked) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying TimeLocked challenge...");
        console.log("Deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy with initial funding
        uint256 initialFunding = 5 ether;
        timeLocked = new TimeLocked{value: initialFunding}();
        
        vm.stopBroadcast();
        
        console.log("TimeLocked deployed at:", address(timeLocked));
        console.log("Contract balance:", address(timeLocked).balance);
        console.log("Admin:", timeLocked.admin());
        
        return timeLocked;
    }
}