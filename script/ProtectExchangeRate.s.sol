// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Lender, ERC20} from "aloe-ii-core/Lender.sol";

import {OracleUpdateHelper, IUniswapV3Pool} from "src/OracleUpdateHelper.sol";

import "./Keeper.s.sol";

contract ProtectExchangeRateScript is KeeperScript {
    address constant burnAddress = 0xdeAD00000000000000000000000000000000dEAd;

    function setUp() public {}

    function run() external {
        Factory factory = _factory[block.chainid];
        IUniswapV3Pool[] storage pools = _getPoolsFor(block.chainid);

        for (uint256 i = 0; i < pools.length; i++) {
            (Lender lender0, Lender lender1, ) = factory.getMarket(pools[i]);
            uint256 threshold = 0.99e18;

            uint256 exchangeRate;
            bool needsDeaden0;
            bool needsDeaden1;

            (exchangeRate, needsDeaden0) = _getExchangeRate(lender0);
            if (exchangeRate < threshold) {
                needsDeaden0 = false;
                console2.log("-", address(lender0), exchangeRate);
            }
            (exchangeRate, needsDeaden1) = _getExchangeRate(lender1);
            if (exchangeRate < threshold) {
                needsDeaden1 = false;
                console2.log("-", address(lender1), exchangeRate);
            }

            vm.startBroadcast(vm.envUint("PRIVATE_KEY_OTHER"));
            if (needsDeaden0) {
                console2.log("+", address(lender0), lender0.asset().symbol());
                lender0.asset().approve(address(lender0), 1e5);
                lender0.deposit(1e5, burnAddress, 0);
            }
            if (needsDeaden1) {
                console2.log("+", address(lender1), lender1.asset().symbol());
                lender1.asset().approve(address(lender1), 1e5);
                lender1.deposit(1e5, burnAddress, 0);
            }
            vm.stopBroadcast();
        }
    }

    function _getExchangeRate(Lender lender) private view returns (uint256, bool) {
        ERC20 asset = lender.asset();
        uint256 decimals = asset.decimals();
        uint256 amount = 10 ** decimals;
        
        return ((lender.convertToShares(amount) * 1e18) / amount, lender.underlyingBalance(burnAddress) < 9999);
    }
}
