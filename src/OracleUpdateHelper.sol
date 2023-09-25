// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VolatilityOracle, IUniswapV3Pool} from "aloe-ii-core/VolatilityOracle.sol";

contract OracleUpdateHelper {
    VolatilityOracle public immutable ORACLE;

    constructor(VolatilityOracle oracle) {
        ORACLE = oracle;
    }

    function update(IUniswapV3Pool[] calldata pools) external {
        unchecked {
            uint256 count = pools.length;
            for (uint256 i = 0; i < count; i++) {
                // On L2's like Optimism, calldata is expensive, so it's cheaper to do binary search onchain.
                // Setting any of the highest 8 bits tells the `ORACLE` to do that.
                ORACLE.update(pools[i], 1 << 32);
            }
        }
    }

    function update(IUniswapV3Pool[] calldata pools, uint32[] calldata seeds) external {
        unchecked {
            uint256 count = pools.length;
            for (uint256 i = 0; i < count; i++) {
                // On mainnet, execution is expensive, so it's cheaper to compute indices offchain and pass them in.
                // We forward that info to the `ORACLE` here.
                ORACLE.update(pools[i], seeds[i]);
            }
        }
    }
}
