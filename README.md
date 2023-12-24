# Aloe II Examples

Examples elaborating various uses of [Aloe II](https://github.com/aloelabs/aloe-ii).

## Disclaimer

This is experimental software and is provided on an "as is" and "as available" basis. We **do not provide any
warranties** and **will not be liable for any loss incurred** through any use of this codebase.

## Usage

Unlike other Foundry repositories, this is not intended to be `forge install`ed. The easiest way to build off it is to clone it and modify things in-place.

If you don't have Foundry installed, follow the instructions [here](https://book.getfoundry.sh/getting-started/installation).

```bash
# Clone the repository
git clone https://github.com/aloelabs/aloe-ii-examples.git
cd aloe-ii-examples
# Install dependencies
git submodule update --init --recursive
# Build contracts
forge build
```

Once everything is installed, there are two scripts you can run. Both assume you have a `.env` file formatted like the [.env.template](/.env.template).

### Liquidate

The [liquidation script](/script/Liquidate.s.sol) gets a list of `Borrower`s on the specified chain using a `cast logs` command (thus necessitating the `--ffi` flag). It checks the health of each `Borrower` and `warns` or `liquidates` the unhealthy ones as appropriate.

```bash
source .env

export LIQUIDATOR_CHAIN='mainnet'
forge script script/Liquidate.s.sol:LiquidateScript --chain $LIQUIDATOR_CHAIN --rpc-url $LIQUIDATOR_CHAIN -vv --ffi --broadcast
```

### Update Oracle

The [update oracle script](/script/UpdateOracle.s.sol) pokes the `VolatilityOracle` for all pools listed in [`Keeper.s.sol`](/script/Keeper.s.sol). New fee growth globals (for each pool) can be stored
once every 4 hours－more frequent calls are no-ops. The implied volatility will be updated if there is a fee growth globals data point between 70 and 74 hours old.

```bash
source .env

forge script script/UpdateOracle.s.sol:UpdateOracleScript --chain mainnet --rpc-url mainnet -vv --broadcast
```

## Future Work

We plan to update this repository with additional examples, such as:

- Script for getting the `oracleSeed`
- An `IManager` that fulfills Uniswap X orders using Aloe II liquidity
- Enrollment flow for couriers
