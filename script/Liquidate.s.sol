// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {LibString} from "solady/utils/LibString.sol";

import {Borrower, Prices} from "aloe-ii-core/Borrower.sol";
import {Factory} from "aloe-ii-core/Factory.sol";
import {BorrowerLens} from "aloe-ii-periphery/BorrowerLens.sol";

import {Liquidator, ERC20} from "src/Liquidator.sol";

contract LiquidateScript is Script {
    using stdJson for string;

    Factory constant FACTORY = Factory(0x000000009efdB26b970bCc0085E126C9dfc16ee8);
    bytes32 constant CREATE_BORROWER_TOPIC0 = 0x1ff0a9a76572c6e0f2f781872c1e45b4bab3a0d90df274ebf884b4c11e3068f4;
    Liquidator constant LIQUIDATOR = Liquidator(payable(0xC8eD78424824Ff7eA3602733909eC57c7d7F7301));

    function run() external {
        string memory json = _getLogs(vm.envString("LIQUIDATOR_CHAIN"), address(FACTORY), CREATE_BORROWER_TOPIC0);
        address[] memory borrowers = _decodeBorrowers(json);
        uint256 count = borrowers.length;

        // List all borrowers in the console
        string memory tag = LibString.concat("[", LibString.concat(LibString.toString(block.chainid), "]\t"));
        console2.log(tag, count, "borrowers found");

        for (uint256 i = 0; i < count; i++) {
            Borrower borrower = Borrower(payable(borrowers[i]));

            string memory borrowerTag = LibString.concat(tag, LibString.toHexString(address(borrower)));

            if (LIQUIDATOR.canWarn(borrower)) {
                console2.log(borrowerTag, unicode"→ unhealthy, calling warn");

                vm.startBroadcast(vm.envUint("PRIVATE_KEY_LIQUIDATE"));
                borrower.warn(1 << 32);
                vm.stopBroadcast();
                continue;
            }

            (bool canLiquidate, int256 auctionTime) = LIQUIDATOR.canLiquidate(borrower);
            if (!canLiquidate) {
                console2.log(borrowerTag, unicode"→ healthy");
                continue;
            }
            if (auctionTime < 5 minutes) {
                console2.log(string.concat(borrowerTag, unicode"→ waiting @ t ="), auctionTime);
                continue;
            }
            console2.log(string.concat(borrowerTag, unicode"→ liquidating @ t ="), auctionTime);

            address pool = address(borrower.UNISWAP_POOL());
            ERC20 token0 = borrower.TOKEN0();
            ERC20 token1 = borrower.TOKEN1();
            address lender0 = address(borrower.LENDER0());
            address lender1 = address(borrower.LENDER1());
            bytes memory data =
                abi.encode(pool, token0, token1, lender0, lender1, vm.addr(vm.envUint("PRIVATE_KEY_LIQUIDATE")));

            vm.startBroadcast(vm.envUint("PRIVATE_KEY_LIQUIDATE"));
            LIQUIDATOR.liquidate(borrower, data, 10000, 1 << 32);
            vm.stopBroadcast();
        }
    }

    function _getLogs(string memory chain, address target, bytes32 topic0) private returns (string memory json) {
        string[] memory cmd = new string[](12);
        cmd[0] = "cast";
        cmd[1] = "logs";
        cmd[2] = "--address";
        cmd[3] = LibString.toHexString(target);
        cmd[4] = "--from-block";
        cmd[5] = "earliest";
        cmd[6] = "--chain";
        cmd[7] = chain;
        cmd[8] = "--rpc-url";
        cmd[9] = chain;
        cmd[10] = "--json";
        cmd[11] = LibString.toHexString(uint256(topic0), 32);

        json = string(vm.ffi(cmd));
    }

    function _decodeBorrowers(string memory json) private view returns (address[] memory) {
        // Decode list of borrowers
        bytes memory dataForEachEvent = json.parseRaw("[:].data");

        address[] memory borrowers;
        if (dataForEachEvent.length == 32) {
            borrowers = new address[](1);
            borrowers[0] = address(uint160(uint256(bytes32(dataForEachEvent))));
            return borrowers;
        }

        uint256 count;
        assembly ("memory-safe") {
            // dataForEachEvent[0:32]   -   number of bytes of data
            // dataForEachEvent[32:64]  -   length of each entry in bytes
            // dataForEachEvent[64:96]  -   number of entries
            count := mload(add(dataForEachEvent, 64))
        }
        uint256 len = count << 5;

        borrowers = new address[](count);
        assembly ("memory-safe") {
            let success := staticcall(gas(), 4, add(dataForEachEvent, 96), len, add(borrowers, 32), len)
        }
        return borrowers;
    }
}
