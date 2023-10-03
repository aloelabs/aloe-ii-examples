// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OracleUpdateHelper, IUniswapV3Pool} from "src/OracleUpdateHelper.sol";

import {KeeperScript} from "./Keeper.s.sol";

contract UpdateOracleScript is KeeperScript {
    function setUp() public {}

    function run() external {
        // vm.createSelectFork(vm.rpcUrl("optimism"));
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // OracleUpdateHelper(0xB93d750Cc6CA3d1F494DC25e7375860feef74870).update(poolsOptimism);
        // vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("arbitrum"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        OracleUpdateHelper(0xDF47F3C81898D9cC3e61979ADD2756ef44893fFa).update(poolsArbitrum);
        vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("base"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        OracleUpdateHelper(0xDF47F3C81898D9cC3e61979ADD2756ef44893fFa).update(poolsBase);
        vm.stopBroadcast();
    }
}
