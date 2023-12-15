// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {OracleUpdateHelper, VolatilityOracle} from "src/OracleUpdateHelper.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_UPDATE_ORACLE"));
        new OracleUpdateHelper{
            salt: 0x0000000000000000000000000000000000000000A10EA10EA10EA10EA10EA10E
        }(VolatilityOracle(0x0000000030d51e39a2dDDb5Db50F9d74a289DFc3));
        vm.stopBroadcast();
    }
}
