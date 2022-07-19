// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "./TestUtils.sol";

import "../src/UniswapV3Pool.sol";
import "../src/lib/LiquidityMath.sol";
import "../src/lib/TickMath.sol";

contract UniswapV3PoolTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;

    bool transferInMintCallback = true;

    int24 tick4000 = 82994;
    int24 tick4545 = 84222;
    int24 tick5000 = 85176;
    int24 tick5000Minus1 = 85175;
    int24 tick5000Plus1 = 85177;
    int24 tick5500 = 86129;
    int24 tick6250 = 87407;

    uint160 sqrtP4000 = TickMath.getSqrtRatioAtTick(tick4000);
    uint160 sqrtP4545 = TickMath.getSqrtRatioAtTick(tick4545);
    uint160 sqrtP5000 = TickMath.getSqrtRatioAtTick(tick5000);
    uint160 sqrtP5000Minus1 = TickMath.getSqrtRatioAtTick(tick5000Minus1);
    uint160 sqrtP5000Plus1 = TickMath.getSqrtRatioAtTick(tick5000Plus1);
    uint160 sqrtP5500 = TickMath.getSqrtRatioAtTick(tick5500);
    uint160 sqrtP6250 = TickMath.getSqrtRatioAtTick(tick6250);

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

    function testMintInRange() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = LiquidityRange({
            lowerTick: tick4545,
            upperTick: tick5500,
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP5000,
                sqrtP4545,
                sqrtP5500,
                1 ether,
                5000 ether
            )
        });
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: tick5000,
            currentSqrtP: sqrtP5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0.998995580131581600 ether,
            4999.999999999999999999 ether
        );

        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: liquidity[0].lowerTick,
                upperTick: liquidity[0].upperTick,
                positionLiquidity: liquidity[0].amount,
                currentLiquidity: liquidity[0].amount,
                sqrtPriceX96: sqrtP5000
            })
        );
    }

    function testMintRangeBelow() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = LiquidityRange({
            lowerTick: tick4000,
            upperTick: tick5000 - 1,
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP5000,
                sqrtP4000,
                sqrtP5000Minus1,
                1 ether,
                5000 ether
            )
        });
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: tick5000,
            currentSqrtP: sqrtP5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0 ether,
            4999.999999999999999995 ether
        );

        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: liquidity[0].lowerTick,
                upperTick: liquidity[0].upperTick,
                positionLiquidity: liquidity[0].amount,
                currentLiquidity: 0,
                sqrtPriceX96: sqrtP5000
            })
        );
    }

    function testMintRangeAbove() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = LiquidityRange({
            lowerTick: tick5000 + 1,
            upperTick: tick6250,
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP5000,
                sqrtP5000Plus1,
                sqrtP6250,
                1 ether,
                5000 ether
            )
        });
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 10 ether,
            usdcBalance: 5000 ether,
            currentTick: tick5000,
            currentSqrtP: sqrtP5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (1 ether, 0);

        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: liquidity[0].lowerTick,
                upperTick: liquidity[0].upperTick,
                positionLiquidity: liquidity[0].amount,
                currentLiquidity: 0,
                sqrtPriceX96: sqrtP5000
            })
        );
    }

    //
    //          5000
    //   4545 ----|---- 5500
    // 4000 ------|------ 6250
    //
    function testMintOverlappingRanges() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = LiquidityRange({
            lowerTick: tick4545,
            upperTick: tick5500,
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP5000,
                sqrtP4545,
                sqrtP5500,
                1 ether,
                5000 ether
            )
        });
        liquidity[1] = LiquidityRange({
            lowerTick: tick4000,
            upperTick: tick6250,
            amount: (liquidity[0].amount * 75) / 100
        });
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 3 ether,
            usdcBalance: 15000 ether,
            currentTick: tick5000,
            currentSqrtP: sqrtP5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        setupTestCase(params);

        (uint256 amount0, uint256 amount1) = (
            2.698571339742487358 ether,
            13321.078959050882134353 ether
        );

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: amount0,
                amount1: amount1,
                lowerTick: tick4545,
                upperTick: tick5500,
                positionLiquidity: liquidity[0].amount,
                currentLiquidity: liquidity[0].amount + liquidity[1].amount,
                sqrtPriceX96: sqrtP5000
            })
        );
        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: amount0,
                amount1: amount1,
                lowerTick: tick4000,
                upperTick: tick6250,
                positionLiquidity: liquidity[1].amount,
                currentLiquidity: liquidity[0].amount + liquidity[1].amount,
                sqrtPriceX96: sqrtP5000
            })
        );
    }

    function testMintInvalidTickRangeLower() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        pool.mint(address(this), -887273, 0, 0, "");
    }

    function testMintInvalidTickRangeUpper() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        pool.mint(address(this), 0, 887273, 0, "");
    }

    function testMintZeroLiquidity() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );

        vm.expectRevert(encodeError("ZeroLiquidity()"));
        pool.mint(address(this), 0, 1, 0, "");
    }

    function testMintInsufficientTokenBalance() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = LiquidityRange({
            lowerTick: tick4545,
            upperTick: tick5500,
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP5000,
                sqrtP4545,
                sqrtP5500,
                1 ether,
                5000 ether
            )
        });
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0,
            usdcBalance: 0,
            currentTick: tick5000,
            currentSqrtP: sqrtP5000,
            liquidity: liquidity,
            transferInMintCallback: false,
            transferInSwapCallback: true,
            mintLiqudity: false
        });
        setupTestCase(params);

        vm.expectRevert(encodeError("InsufficientInputAmount()"));
        pool.mint(
            address(this),
            liquidity[0].lowerTick,
            liquidity[0].upperTick,
            liquidity[0].amount,
            ""
        );
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // CALLBACKS
    //
    ////////////////////////////////////////////////////////////////////////////
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        if (transferInMintCallback) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (UniswapV3Pool.CallbackData)
            );

            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ////////////////////////////////////////////////////////////////////////////
    function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        if (params.mintLiqudity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);

            bytes memory extra = encodeExtra(
                address(token0),
                address(token1),
                address(this)
            );

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < params.liquidity.length; i++) {
                (poolBalance0Tmp, poolBalance1Tmp) = pool.mint(
                    address(this),
                    params.liquidity[i].lowerTick,
                    params.liquidity[i].upperTick,
                    params.liquidity[i].amount,
                    extra
                );
                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }

        transferInMintCallback = params.transferInMintCallback;
    }
}
