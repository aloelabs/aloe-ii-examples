// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OracleUpdateHelper, IUniswapV3Pool} from "src/OracleUpdateHelper.sol";

import {KeeperScript} from "./Keeper.s.sol";

contract UpdateOracleScript is KeeperScript {
    function setUp() public {}

    function run() external {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        OracleUpdateHelper(0x0F574c68dDa1181DE99eBe86E1639A9E33354077).update(poolsMainnet);
        vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("optimism"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        OracleUpdateHelper(0x0F574c68dDa1181DE99eBe86E1639A9E33354077).update(poolsOptimism);
        vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("arbitrum"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        OracleUpdateHelper(0x0F574c68dDa1181DE99eBe86E1639A9E33354077).update(poolsArbitrum);
        vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("base"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        OracleUpdateHelper(0x0F574c68dDa1181DE99eBe86E1639A9E33354077).update(poolsBase);
        vm.stopBroadcast();
    }
}
