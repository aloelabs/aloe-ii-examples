// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {OracleUpdateHelper, IUniswapV3Pool} from "src/OracleUpdateHelper.sol";

import "./Keeper.s.sol";

contract UpdateOracleScript is KeeperScript {
    OracleUpdateHelper constant oracleUpdateHelper = OracleUpdateHelper(0x63cd7973D2416ae5cA46231dfd358C75fbC39670);

    uint256 constant updateThreshold = 0.0001e12;

    function setUp() public {}

    function run() external {
        VolatilityOracle oracle = _oracle[block.chainid];
        IUniswapV3Pool[] storage pools = _getPoolsFor(block.chainid);

        IUniswapV3Pool[] memory poolsToUpdate = new IUniswapV3Pool[](pools.length);
        uint256 j;
        for (uint256 i; i < pools.length; i++) {
            (, uint40 time,,) = oracle.lastWrites(pools[i]);

            if (block.timestamp - time < 4 hours) continue;

            oracle.update(pools[i], 1 << 32);
            (, time,,) = oracle.lastWrites(pools[i]);
            if (time != block.timestamp) continue;

            poolsToUpdate[j] = pools[i];
            j++;
            console2.log(address(pools[i]));
        }

        assembly ("memory-safe") {
            mstore(poolsToUpdate, j)
        }

        if (poolsToUpdate.length > 0) {
            vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
            oracleUpdateHelper.update(oracle, poolsToUpdate);
            vm.stopBroadcast();
        }
    }
}
