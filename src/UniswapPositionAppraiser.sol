// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {VolatilityOracle, IUniswapV3Pool} from "aloe-ii-core/VolatilityOracle.sol";
import {square, mulDiv128} from "aloe-ii-core/libraries/MulDiv.sol";

import {IUniswapPositionNFT} from "aloe-ii-periphery/interfaces/IUniswapPositionNFT.sol";
import {Uniswap} from "aloe-ii-periphery/libraries/Uniswap.sol";

contract UniswapPositionAppraiser {
    using LibString for string;
    using Uniswap for Uniswap.Position;

    address public immutable UNISWAP_FACTORY;

    IUniswapPositionNFT public immutable UNISWAP_NFT;

    VolatilityOracle public immutable ORACLE;

    constructor(
        address uniswapFactory,
        IUniswapPositionNFT uniswapNft,
        VolatilityOracle oracle
    ) {
        UNISWAP_FACTORY = uniswapFactory;
        UNISWAP_NFT = uniswapNft;
        ORACLE = oracle;
    }

    function getFormattedAppraisal(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory valueInTermsOf0Str,
            string memory valueInTermsOf1Str
        )
    {
        (
            IUniswapV3Pool pool,
            ,
            ,
            ,
            ,
            uint256 valueInTermsOf0,
            uint256 valueInTermsOf1
        ) = getAppraisal(tokenId);

        valueInTermsOf0Str = _toString(valueInTermsOf0, ERC20(pool.token0()));
        valueInTermsOf1Str = _toString(valueInTermsOf1, ERC20(pool.token1()));
    }

    function getAppraisal(
        uint256 tokenId
    )
        public
        view
        returns (
            IUniswapV3Pool pool,
            uint256 fees0,
            uint256 fees1,
            uint256 amount0,
            uint256 amount1,
            uint256 valueInTermsOf0,
            uint256 valueInTermsOf1
        )
    {
        Uniswap.Position memory position;
        Uniswap.PositionInfo memory positionInfo;

        {
            address token0;
            address token1;
            uint24 fee;
            (
                ,
                ,
                token0,
                token1,
                fee,
                position.lower,
                position.upper,
                positionInfo.liquidity,
                positionInfo.feeGrowthInside0LastX128,
                positionInfo.feeGrowthInside1LastX128,
                positionInfo.tokensOwed0,
                positionInfo.tokensOwed1
            ) = UNISWAP_NFT.positions(tokenId);

            pool = Uniswap.computePoolAddress(
                UNISWAP_FACTORY,
                token0,
                token1,
                fee
            );
        }

        Uniswap.FeeComputationCache memory fcc;
        (, fcc.currentTick, , , , , ) = pool.slot0();
        fcc.feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        fcc.feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();

        (fees0, fees1) = position.fees(pool, positionInfo, fcc);

        (, uint160 sqrtPriceX96, ) = ORACLE.consult(pool, 1 << 32);
        (amount0, amount1) = position.amountsForLiquidity(
            sqrtPriceX96,
            positionInfo.liquidity
        );

        uint256 priceX128 = square(sqrtPriceX96);
        valueInTermsOf1 =
            amount1 +
            fees1 +
            mulDiv128(amount0 + fees0, priceX128);
        valueInTermsOf0 =
            amount0 +
            fees0 +
            SoladyMath.fullMulDiv(amount1 + fees1, 1 << 128, priceX128);
    }

    function _toString(
        uint256 amount,
        ERC20 token
    ) private view returns (string memory str) {
        str = LibString.toString(amount);

        int256 log10 = -int8(token.decimals());
        while (amount >= 10) {
            amount /= 10;
            log10++;
        }

        if (log10 < 0) {
            str = LibString.repeat("0", uint256(-log10)).concat(str);
        }

        uint256 digitsBeforeDecimal = uint256(SoladyMath.max(0, log10)) + 1;
        str = str.slice(0, digitsBeforeDecimal).concat(".").concat(
            str.slice(digitsBeforeDecimal)
        );
        str = str.concat(" ").concat(token.symbol());
    }
}
