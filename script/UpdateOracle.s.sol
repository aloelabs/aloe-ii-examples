// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

import {OracleUpdateHelper, IUniswapV3Pool} from "src/OracleUpdateHelper.sol";

import {KeeperScript} from "./Keeper.s.sol";

contract UpdateOracleScript is KeeperScript {
    OracleUpdateHelper constant oracleUpdateHelper = OracleUpdateHelper(0x0F574c68dDa1181DE99eBe86E1639A9E33354077);

    uint256 constant updateThreshold = 0.0001e12;

    function setUp() public {}

    function run() external {
        IUniswapV3Pool[] storage pools = _getPoolsFor(block.chainid);

        IUniswapV3Pool[] memory poolsToUpdate = new IUniswapV3Pool[](pools.length);
        uint256 j;
        for (uint256 i; i < pools.length; i++) {
            (, uint40 oldTime, , ) = oracleUpdateHelper.ORACLE().lastWrites(pools[i]);

            if (block.timestamp - oldTime < 1 days) {
                oracleUpdateHelper.ORACLE().update(pools[i], 1 << 32);
                (, uint40 time, uint256 oldIV, uint256 newIV) = oracleUpdateHelper.ORACLE().lastWrites(pools[i]);

                if (time != block.timestamp) continue;
                if (FixedPointMathLib.abs(int256(newIV) - int256(oldIV)) < updateThreshold) continue;
            }

            poolsToUpdate[j] = pools[i];
            j++;
            console2.log(address(pools[i]));
        }

        assembly ("memory-safe") {
            mstore(poolsToUpdate, j)
        }

        if (poolsToUpdate.length > 0) {
            vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
            oracleUpdateHelper.update(poolsToUpdate);
            vm.stopBroadcast();
        }
    }
}
