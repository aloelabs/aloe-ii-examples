// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {Factory} from "aloe-ii-core/Factory.sol";

abstract contract KeeperScript is Script {
    Factory constant FACTORY = Factory(0x000000009efdB26b970bCc0085E126C9dfc16ee8);

    IUniswapV3Pool[] poolsMainnet = [
        IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640), // USDC/WETH 0.05%
        IUniswapV3Pool(0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0), // WBTC/WETH 0.05%
        IUniswapV3Pool(0x109830a1AAaD605BbF02a9dFA7B0B92EC2FB7dAa), // wstETH/WETH 0.01%
        IUniswapV3Pool(0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35) // WBTC/USDC 0.30%
        // IUniswapV3Pool(0xe8c6c9227491C0a8156A0106A0204d881BB7E531), // MKR/WETH 0.30%
        // IUniswapV3Pool(0xa3f558aebAecAf0e11cA4b2199cC5Ed341edfd74), // LDO/WETH 0.30%
        // IUniswapV3Pool(0x1d42064Fc4Beb5F8aAF85F4617AE8b3b5B8Bd801), // UNI/WETH 0.30%
        // IUniswapV3Pool(0x290A6a7460B308ee3F19023D2D00dE604bcf5B42), // MATIC/WETH 0.30%
        // IUniswapV3Pool(0xe42318eA3b998e8355a3Da364EB9D48eC725Eb45), // WETH/RPL 0.30%
        // IUniswapV3Pool(0xAc4b3DacB91461209Ae9d41EC517c2B9Cb1B7DAF), // APE/WETH 0.30%
        // IUniswapV3Pool(0x2E4784446A0a06dF3D1A040b03e1680Ee266c35a) // CVX/WETH 1.0%
    ];

    IUniswapV3Pool[] poolsOptimism = [
        IUniswapV3Pool(0x68F5C0A2DE713a54991E01858Fd27a3832401849), // WETH/OP 0.30%
        IUniswapV3Pool(0x85149247691df622eaF1a8Bd0CaFd40BC45154a9), // WETH/USDC 0.05%
        IUniswapV3Pool(0xF1F199342687A7d78bCC16fce79fa2665EF870E1), // USDC/USDT 0.01%
        IUniswapV3Pool(0x85C31FFA3706d1cce9d525a00f1C7D4A2911754c), // WETH/WBTC 0.05%
        IUniswapV3Pool(0xbf16ef186e715668AA29ceF57e2fD7f9D48AdFE6), // USDC/DAI 0.01%
        IUniswapV3Pool(0x1C3140aB59d6cAf9fa7459C6f83D4B52ba881d36), // OP/USDC 0.30%
        IUniswapV3Pool(0x535541F1aa08416e69Dc4D610131099FA2Ae7222), // WETH/PERP 0.30%
        IUniswapV3Pool(0x22F5F609C554B89792B14B91BAdCCaF52c156E95), // POOL/WETH 1.0%
        IUniswapV3Pool(0x0392b358CE4547601BEFa962680BedE836606ae2) // WETH/SNX 0.3%
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
        IUniswapV3Pool(0x9E37cb775a047Ae99FC5A24dDED834127c4180cD), // BALD/WETH 1.0%
        IUniswapV3Pool(0xa555149210075702A734968F338d5E1CBd509354) // WETH/BASED 0.30%
    ];

    function _getPoolsFor(uint256 chainId) internal view returns (IUniswapV3Pool[] storage pools) {
        if (chainId == 1) {
            pools = poolsMainnet;
        } else if (chainId == 10) {
            pools = poolsOptimism;
        } else if (chainId == 42161) {
            pools = poolsArbitrum;
        } else if (chainId == 8453) {
            pools = poolsBase;
        } else {
            revert("No pools array for this chain");
        }
    }
}
