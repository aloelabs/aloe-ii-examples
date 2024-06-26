// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";

import {Prices} from "aloe-ii-core/libraries/BalanceSheet.sol";

import {BadDebtProcessor, IUniswapV3Pool, Borrower, Lender, ERC20} from "src/BadDebtProcessor.sol";

interface ISuperRegistry {
    function getAddress(bytes32 hash) external view returns (address);
}

interface IERC4626Form {
    function vault() external view returns (Lender);

    function superRegistry() external view returns (ISuperRegistry);

    function emergencyWithdraw(address to, uint256 amount) external;
}

contract ExampleDistributor {
    IERC4626Form public immutable FORM;

    BadDebtProcessor public immutable PROCESSOR;

    ERC20 public token0;

    ERC20 public token1;

    constructor(IERC4626Form form) {
        FORM = form;
        PROCESSOR = new BadDebtProcessor();
    }

    // TODO: Merkle-based (or other method of) pro-rata distribution of both tokens to FORM users

    function emergencyWithdraw(ERC20 token, address to, uint256 amount) external {
        require(msg.sender == FORM.superRegistry().getAddress(keccak256("EMERGENCY_QUEUE")), "Only EMERGENCY_QUEUE");
        token.transfer(to, amount);
    }

    function processBadDebt(
        Borrower borrower,
        IUniswapV3Pool flashPool,
        uint256 minReceived0,
        uint256 minReceived1
    ) external {
        require(msg.sender == FORM.superRegistry().getAddress(keccak256("EMERGENCY_QUEUE")), "Only EMERGENCY_QUEUE");

        Lender lender = FORM.vault();
        lender.approve(address(PROCESSOR), type(uint256).max);
        PROCESSOR.process(lender, borrower, flashPool, 10); // max loss of 0.1% to flash swap fees

        token0 = borrower.TOKEN0();
        require(token0.balanceOf(address(this)) > minReceived0, "expected more token0");
        token1 = borrower.TOKEN1();
        require(token1.balanceOf(address(this)) > minReceived1, "expected more token1");
    }
}

contract BadDebtProcessorTest is Test {
    BadDebtProcessor processor;

    function setUp() public {
        processor = new BadDebtProcessor();

        vm.createSelectFork(vm.rpcUrl("base"));
        vm.rollFork(16280514);
    }

    function testDistributor() public {
        // WETH+ Form -- the one impacted by bad debt, and from which users won't be able to withdraw normally
        IERC4626Form form = IERC4626Form(0xa5254fF645494d93635360c1cacC375191023a8A);
        // The borrower whose debt can only be liquidated lossily
        Borrower borrower = Borrower(payable(0xC7Cdda63Bf761c663FD7058739be847b422aA5A2));
        // The contract that will process the bad debt and distribute the borrower's collateral to users.
        // When used, this essentially accepts the loss from bad debt, receiving any remaining collateral
        // even though that collateral isn't worth as much as the nominal deposits.
        // In this case (at current prices), users would get back ~45 cents on the dollar.
        ExampleDistributor distributor = new ExampleDistributor(form);

        uint256 nominalEthBalance = form.vault().underlyingBalance(address(form));
        console2.log("WETH balance (nominal):", nominalEthBalance);
        console2.log("WETH balance (redeemable):", form.vault().maxWithdraw(address(form)));

        vm.startPrank(form.superRegistry().getAddress(keccak256("EMERGENCY_QUEUE")));
        // Move WETH+ shares from the form to the distributor
        form.emergencyWithdraw(address(distributor), form.vault().balanceOf(address(form)));
        // Redeem shares for the unhealthy borrower's collateral (users can then decide to sell immediately for ETH, or hold and hope value goes back up)
        // Revert if we don't get at least 76,000 BASED tokens.
        distributor.processBadDebt(
            borrower, IUniswapV3Pool(0x20E068D76f9E90b90604500B84c7e19dCB923e7e), 8.5 ether, 76_000e18
        );

        uint256 ethReceived = distributor.token0().balanceOf(address(distributor));
        uint256 basedReceived = distributor.token1().balanceOf(address(distributor));
        console2.log("WETH received:", ethReceived);
        console2.log("BASED received:", basedReceived);

        (Prices memory prices,,,) = borrower.getPrices(1 << 32);
        uint256 priceX128 = SoladyMath.fullMulDiv(prices.c, prices.c, 1 << 64);
        uint256 basedReceivedInTermsOfEth = SoladyMath.fullMulDiv(basedReceived, 1 << 128, priceX128);
        console2.log(
            "Recovery fraction at current price:",
            (ethReceived + basedReceivedInTermsOfEth) * 10_000 / nominalEthBalance,
            "/ 10000"
        );
    }

    function testBadDebtProcessor() public {
        IERC4626Form form = IERC4626Form(0xa5254fF645494d93635360c1cacC375191023a8A);
        ISuperRegistry superRegistry = form.superRegistry();
        address emergencyAddress = superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"));

        console2.log(emergencyAddress);

        Lender lender = form.vault();
        uint256 shares = lender.balanceOf(address(form));

        address receiver = address(12345);

        vm.prank(emergencyAddress);
        form.emergencyWithdraw(receiver, shares);

        Borrower borrower = Borrower(payable(0xC7Cdda63Bf761c663FD7058739be847b422aA5A2));

        vm.startPrank(receiver);
        lender.approve(address(processor), type(uint256).max); // NOTE: Dangerous outside of test-env, would want this to be atomic with debt processing
        processor.process(
            lender,
            borrower,
            IUniswapV3Pool(0x20E068D76f9E90b90604500B84c7e19dCB923e7e),
            10 // 0.1% slippage
        );
        vm.stopPrank();

        console2.log("receiver shares (t0)", shares);
        console2.log("receiver shares (t1)", lender.balanceOf(receiver));
        console2.log("receiver token0 (t1)", borrower.TOKEN0().balanceOf(receiver));
        console2.log("receiver token1 (t1)", borrower.TOKEN1().balanceOf(receiver));
        console2.log("processor token0 (t1)", borrower.TOKEN0().balanceOf(address(processor)));
        console2.log("processor token1 (t1)", borrower.TOKEN1().balanceOf(address(processor)));
        console2.log("lender assets (t1)", lender.asset().balanceOf(address(lender)));

        (uint256 a, uint256 b) = borrower.getLiabilities();
        console2.log(a, b);
    }
}
