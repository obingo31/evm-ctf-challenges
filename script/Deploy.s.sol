pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../challenges/01-Reentrancy/src/Reentrance.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        new Reentrance();
        vm.stopBroadcast();
    }
}
