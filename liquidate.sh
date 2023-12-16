#!/bin/bash

forge build

for ((i = 1; i <= $1; i++)); do
    source .env

    LIQUIDATOR_CHAIN='mainnet' forge script script/Liquidate.s.sol:LiquidateScript --chain mainnet --rpc-url mainnet -vv --ffi --broadcast &
    LIQUIDATOR_CHAIN='optimism' forge script script/Liquidate.s.sol:LiquidateScript --chain optimism --rpc-url optimism -vv --ffi --broadcast &
    LIQUIDATOR_CHAIN='arbitrum' forge script script/Liquidate.s.sol:LiquidateScript --chain arbitrum --rpc-url arbitrum -vv --ffi --broadcast &
    LIQUIDATOR_CHAIN='base' forge script script/Liquidate.s.sol:LiquidateScript --chain base --rpc-url base -vv --ffi --broadcast &
    wait  # Wait for background processes to finish

    sleep "$2"
done
