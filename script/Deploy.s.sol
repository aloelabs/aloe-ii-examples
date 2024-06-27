// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {BadDebtProcessor} from "src/BadDebtProcessor.sol";
import {Liquidator} from "src/Liquidator.sol";
import {OracleUpdateHelper, VolatilityOracle} from "src/OracleUpdateHelper.sol";
import {UniswapPositionAppraiser, IUniswapPositionNFT} from "src/UniswapPositionAppraiser.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        new OracleUpdateHelper{salt: 0x0000000000000000000000000000000000000000A10EA10EA10EA10EA10EA10E}();
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY_LIQUIDATE"));
        new Liquidator{salt: 0x0000000000000000000000000000000000000000A10EA10EA10EA10EA10EA10E}();
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY_OTHER"));
        new BadDebtProcessor{salt: 0x0000000000000000000000000000000000000000A10EA10EA10EA10EA10EA10E}();
        new UniswapPositionAppraiser{salt: 0x0000000000000000000000000000000000000000A10EA10EA10EA10EA10EA10E}(
            0x1F98431c8aD98523631AE4a59f267346ea31F984,
            IUniswapPositionNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88),
            VolatilityOracle(0x0000000030d51e39a2dDDb5Db50F9d74a289DFc3)
        );
        vm.stopBroadcast();
    }
}
