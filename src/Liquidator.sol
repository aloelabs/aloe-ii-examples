// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniswapV3SwapCallback} from "v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {LIQUIDATION_GRACE_PERIOD} from "aloe-ii-core/libraries/constants/Constants.sol";
import {BalanceSheet, AuctionAmounts, Assets, Prices} from "aloe-ii-core/libraries/BalanceSheet.sol";
import {TickMath} from "aloe-ii-core/libraries/TickMath.sol";

import {Borrower, ILiquidator} from "aloe-ii-core/Borrower.sol";

contract Liquidator is ILiquidator, IUniswapV3SwapCallback {
    using SafeTransferLib for ERC20;

    receive() external payable {}

    function liquidate(Borrower borrower, bytes calldata data, uint256 closeFactor, uint40 oracleSeed) external {
        borrower.liquidate(this, data, closeFactor, oracleSeed);
        if (closeFactor == 10000) payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Transfers `amounts.out0` and `amounts.out1` to the liquidator with the expectation that they'll
     * transfer `amounts.repay0` and `amounts.repay1` to the appropriate `Lender`s, executing swaps if necessary.
     * The liquidator can keep leftover funds as a reward.
     * @param data Encoded parameters that were passed to `Borrower.liquidate`
     * @param amounts The key amounts involved in the liquidation
     */
    function callback(bytes calldata data, address, AuctionAmounts memory amounts) external {
        int256 x = int256(amounts.out0) - int256(amounts.repay0);
        int256 y = int256(amounts.out1) - int256(amounts.repay1);

        (IUniswapV3Pool pool, ERC20 token0, ERC20 token1, address lender0, address lender1, address eoa) =
            abi.decode(data, (IUniswapV3Pool, ERC20, ERC20, address, address, address));

        if (x < 0 && y < 0) {
            revert("Clearing bad debt requires donation");
        } else if (y < 0) {
            // Need to swap `token0` for `token1`
            (int256 swapped0,) = pool.swap(address(this), true, y, TickMath.MIN_SQRT_RATIO + 1, bytes(""));
            x -= swapped0;
        } else if (x < 0) {
            // Need to swap `token1` for `token0`
            (, int256 swapped1) = pool.swap(address(this), false, x, TickMath.MAX_SQRT_RATIO - 1, bytes(""));
            y -= swapped1;
        }

        if (x > 0) token0.safeTransfer(eoa, uint256(x));
        if (y > 0) token1.safeTransfer(eoa, uint256(y));
        if (amounts.repay0 > 0) token0.safeTransfer(lender0, amounts.repay0);
        if (amounts.repay1 > 0) token1.safeTransfer(lender1, amounts.repay1);
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) {
            ERC20(IUniswapV3Pool(msg.sender).token0()).safeTransfer(msg.sender, uint256(amount0Delta));
        } else {
            ERC20(IUniswapV3Pool(msg.sender).token1()).safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }

    function canWarn(Borrower borrower) external view returns (bool) {
        uint256 slot0 = borrower.slot0();
        uint256 warnTime = uint40(slot0 >> 208);

        if (warnTime > 0) return false;

        (Prices memory prices,,,) = borrower.getPrices(1 << 32);
        Assets memory assets = borrower.getAssets();
        (uint256 liabilities0, uint256 liabilities1) = borrower.getLiabilities();

        return !BalanceSheet.isHealthy(prices, assets, liabilities0, liabilities1);
    }

    function canLiquidate(Borrower borrower) external view returns (bool, int256) {
        uint256 slot0 = borrower.slot0();
        uint256 warnTime = uint40(slot0 >> 208);
        unchecked {
            return (
                warnTime > 0 && block.timestamp >= warnTime + LIQUIDATION_GRACE_PERIOD,
                warnTime > 0 ? int256(block.timestamp) - int256(warnTime + LIQUIDATION_GRACE_PERIOD) : int256(0)
            );
        }
    }
}
