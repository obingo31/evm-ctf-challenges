// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {CrackMeSolution} from "../src/contracts/CrackMeSolution.sol";

contract SolveCrackMe is Script {
    function run() external {
        address target = vm.envAddress("CRACKME_TARGET");

        vm.startBroadcast();
        CrackMeSolution solver = new CrackMeSolution(target);
        solver.solve();
        vm.stopBroadcast();

        console2.log("CrackMe solved by", address(solver));
    }
}
