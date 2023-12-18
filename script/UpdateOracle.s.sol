// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OracleUpdateHelper, IUniswapV3Pool} from "src/OracleUpdateHelper.sol";

import {KeeperScript} from "./Keeper.s.sol";

contract UpdateOracleScript is KeeperScript {
    OracleUpdateHelper constant oracleUpdateHelper = OracleUpdateHelper(0x0F574c68dDa1181DE99eBe86E1639A9E33354077);

    function setUp() public {}

    function run() external {
        IUniswapV3Pool[] storage pools;
        if (block.chainid == 1) {
            pools = poolsMainnet;
        } else if (block.chainid == 10) {
            pools = poolsOptimism;
        } else if (block.chainid == 42161) {
            pools = poolsArbitrum;
        } else if (block.chainid == 8453) {
            pools = poolsBase;
        } else {
            revert("No pools array for this chain");
        }

        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        oracleUpdateHelper.update(pools);
        vm.stopBroadcast();
    }
}
