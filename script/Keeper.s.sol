// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {Factory} from "aloe-ii-core/Factory.sol";

abstract contract KeeperScript is Script {
    Factory constant FACTORY = Factory(0x000000009efdB26b970bCc0085E126C9dfc16ee8);

    IUniswapV3Pool[] poolsMainnet = [
        IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640) // USDC/WETH 0.05%
    ];

    IUniswapV3Pool[] poolsOptimism = [
        IUniswapV3Pool(0x68F5C0A2DE713a54991E01858Fd27a3832401849), // WETH/OP 0.30%
        IUniswapV3Pool(0x85149247691df622eaF1a8Bd0CaFd40BC45154a9), // WETH/USDC 0.05%
        IUniswapV3Pool(0xF1F199342687A7d78bCC16fce79fa2665EF870E1), // USDC/USDT 0.01%
        IUniswapV3Pool(0x85C31FFA3706d1cce9d525a00f1C7D4A2911754c), // WETH/WBTC 0.05%
        IUniswapV3Pool(0xbf16ef186e715668AA29ceF57e2fD7f9D48AdFE6), // USDC/DAI 0.01%
        IUniswapV3Pool(0x1C3140aB59d6cAf9fa7459C6f83D4B52ba881d36), // OP/USDC 0.30%
        IUniswapV3Pool(0x535541F1aa08416e69Dc4D610131099FA2Ae7222) // WETH/PERP 0.30%
    ];

    IUniswapV3Pool[] poolsArbitrum = [
        IUniswapV3Pool(0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443), // WETH/USDC.e 0.05%
        IUniswapV3Pool(0xC6962004f452bE9203591991D15f6b388e09E8D0), // WETH/USDC 0.05%
        IUniswapV3Pool(0xC6F780497A95e246EB9449f5e4770916DCd6396A), // WETH/ARB 0.05%
        IUniswapV3Pool(0xcDa53B1F66614552F834cEeF361A8D12a0B8DaD8) // ARB/USDC 0.05%
    ];

    IUniswapV3Pool[] poolsBase = [
        IUniswapV3Pool(0x4C36388bE6F416A29C8d8Eee81C771cE6bE14B18), // WETH/USDbC 0.05%
        IUniswapV3Pool(0x10648BA41B8565907Cfa1496765fA4D95390aa0d), // cbETH/WETH 0.05%
        IUniswapV3Pool(0x9E37cb775a047Ae99FC5A24dDED834127c4180cD) // BALD/WETH 1.0%
    ];
}
