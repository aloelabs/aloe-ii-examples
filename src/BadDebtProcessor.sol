// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniswapV3FlashCallback} from "v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import {IUniswapV3SwapCallback} from "v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {AuctionAmounts} from "aloe-ii-core/libraries/BalanceSheet.sol";
import {TickMath} from "aloe-ii-core/libraries/TickMath.sol";

import {Borrower, ILiquidator} from "aloe-ii-core/Borrower.sol";
import {Lender} from "aloe-ii-core/Lender.sol";

contract BadDebtProcessor is ILiquidator, IUniswapV3FlashCallback, IUniswapV3SwapCallback {
    using SafeTransferLib for ERC20;

    receive() external payable {}

    function processWithPermit(
        Lender lender,
        Borrower borrower,
        IUniswapV3Pool flashPool,
        uint256 slippage,
        uint256 allowance,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        lender.permit(msg.sender, address(this), allowance, deadline, v, r, s);
        process(lender, borrower, flashPool, slippage);
    }

    function process(Lender lender, Borrower borrower, IUniswapV3Pool flashPool, uint256 slippage) public {
        uint256 withdrawAmount = lender.underlyingBalance(msg.sender);
        // We assume `withdrawAmount > lender.lastBalance()`, otherwise there's no reason to use this fn
        uint256 repayAmount = (withdrawAmount - lender.lastBalance()) * 10_001 / 10_000;
        uint256 closeFactor = SoladyMath.min((repayAmount * 10_000) / lender.borrowBalance(address(borrower)), 10_000);

        bytes memory data = abi.encode(borrower, closeFactor, msg.sender, repayAmount, slippage);
        if (address(lender.asset()) == flashPool.token0()) {
            flashPool.flash(address(this), repayAmount, 0, data);
        } else {
            flashPool.flash(address(this), 0, repayAmount, data);
        }
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        require(fee0 == 0 || fee1 == 0, "Incompatible situation");

        (Borrower borrower, uint256 closeFactor, address withdrawFrom, uint256 flashAmount, uint256 slippage) =
            abi.decode(data, (Borrower, uint256, address, uint256, uint256));
        borrower.liquidate(this, data, closeFactor, 1 << 32);

        ERC20 flashToken;
        if (fee0 > 0) {
            flashToken = ERC20(IUniswapV3Pool(msg.sender).token0());
            flashAmount += fee0;
        } else {
            flashToken = ERC20(IUniswapV3Pool(msg.sender).token1());
            flashAmount += fee1;
        }

        ERC20 token0 = borrower.TOKEN0();
        ERC20 token1 = borrower.TOKEN1();
        if (token0 == flashToken) {
            borrower.LENDER0().redeem(type(uint256).max, address(this), withdrawFrom);
            int256 exactAmountOut = int256(flashToken.balanceOf(address(this))) - int256(flashAmount);

            uint256 recovered = token1.balanceOf(address(this));
            int256 swapped;
            if (exactAmountOut < 0) {
                // Need to swap `token1` (the one we received in during liquidation) for `token0` (which is `flashToken`)
                (, swapped) = borrower.UNISWAP_POOL().swap(
                    address(this), false, exactAmountOut, TickMath.MAX_SQRT_RATIO - 1, bytes("")
                );
                require(uint256(swapped) < recovered * slippage / 10_000, "slippage");
            }

            token1.safeTransfer(withdrawFrom, recovered - uint256(swapped));
        } else {
            borrower.LENDER1().redeem(type(uint256).max, address(this), withdrawFrom);
            int256 exactAmountOut = int256(flashToken.balanceOf(address(this))) - int256(flashAmount);

            uint256 recovered = token0.balanceOf(address(this));
            int256 swapped;
            if (exactAmountOut < 0) {
                // Need to swap `token0` (the one we received in during liquidation) for `token1` (which is `flashToken`)
                (swapped,) = borrower.UNISWAP_POOL().swap(
                    address(this), true, exactAmountOut, TickMath.MIN_SQRT_RATIO + 1, bytes("")
                );
                require(uint256(swapped) < recovered * slippage / 10_000, "slippage");
            }

            token0.safeTransfer(withdrawFrom, recovered - uint256(swapped));
        }

        flashToken.safeTransfer(msg.sender, flashAmount);
        flashToken.safeTransfer(withdrawFrom, flashToken.balanceOf(address(this)));
        if (closeFactor == 10000) payable(withdrawFrom).transfer(address(this).balance);
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) {
            ERC20(IUniswapV3Pool(msg.sender).token0()).safeTransfer(msg.sender, uint256(amount0Delta));
        } else {
            ERC20(IUniswapV3Pool(msg.sender).token1()).safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }

    /**
     * @notice Transfers `amounts.out0` and `amounts.out1` to the liquidator with the expectation that they'll
     * transfer `amounts.repay0` and `amounts.repay1` to the appropriate `Lender`s, executing swaps if necessary.
     * The liquidator can keep leftover funds as a reward.
     * @param amounts The key amounts involved in the liquidation
     */
    function callback(bytes calldata, address, AuctionAmounts memory amounts) external {
        if (amounts.repay0 > 0) {
            ERC20 token0 = Borrower(payable(msg.sender)).TOKEN0();
            Lender lender0 = Borrower(payable(msg.sender)).LENDER0();
            token0.safeTransfer(address(lender0), amounts.repay0);
        }
        if (amounts.repay1 > 0) {
            ERC20 token1 = Borrower(payable(msg.sender)).TOKEN1();
            Lender lender1 = Borrower(payable(msg.sender)).LENDER1();
            token1.safeTransfer(address(lender1), amounts.repay1);
        }
    }
}
