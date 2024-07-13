// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {IBinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinBaseHook} from "./pool-bin/BinBaseHook.sol";
import {MockOracle} from "./MockOracle.sol";
import {ImpliedOddsHelper} from "./ImpliedOddsHelper.sol";
import {EnglishOrSpanish} from "./EnglishOrSpanish.sol";

/// @notice PredictionMarketHook dynamically adjusts market based on oracle data
contract PredictionMarketHook is BinBaseHook {
    using PoolIdLibrary for PoolKey;

    MockOracle public oracle;
    EnglishOrSpanish public englishOrSpanish;

    mapping(PoolId => uint256) public beforeSwapCount;
    mapping(PoolId => uint256) public afterSwapCount;

    constructor(
        IBinPoolManager _poolManager,
        MockOracle _oracle,
        EnglishOrSpanish _englishOrSpanish
    ) BinBaseHook(_poolManager) {
        oracle = _oracle;
        englishOrSpanish = _englishOrSpanish;
    }

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return
            _hooksRegistrationBitmapFrom(
                Permissions({
                    beforeInitialize: false,
                    afterInitialize: false,
                    beforeMint: false,
                    afterMint: false,
                    beforeBurn: false,
                    afterBurn: false,
                    beforeSwap: true,
                    afterSwap: false,
                    beforeDonate: false,
                    afterDonate: false,
                    beforeSwapReturnsDelta: true,
                    afterSwapReturnsDelta: false,
                    afterMintReturnsDelta: false,
                    afterBurnReturnsDelta: false
                })
            );
    }

    function adjustLiquidity() internal {}

    // Redistribute liquidity for specified pool
    function redistributeLiquidity(string memory outcome, uint256 newProbability) internal {}

    function beforeSwap(
        address,
        PoolKey calldata key,
        bool,
        int128,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4, BeforeSwapDelta, uint24) {
        // Call EnglishOrSpanish to rebalance all 3 Pools
        englishOrSpanish.rebalanceAllPools();

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        bool,
        int128,
        BalanceDelta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4, int128) {
        afterSwapCount[key.toId()]++;
        return (this.afterSwap.selector, 0);
    }
}
