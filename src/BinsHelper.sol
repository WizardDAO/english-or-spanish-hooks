// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ln, unwrap, wrap, UD60x18} from "@prb/math/src/UD60x18.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {IBinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/interfaces/IBinFungiblePositionManager.sol";
import {SafeCast} from "@pancakeswap/v4-core/src/pool-bin/libraries/math/SafeCast.sol";

contract BinsHelper {
    using SafeCast for uint256;
    uint256 constant binStep = 100;
    uint256 constant baseId = 8388608;
    uint256 constant UNIT = 10 ** 18;

    IBinFungiblePositionManager public positionManager;

    constructor(IBinFungiblePositionManager _positionManager) {
        positionManager = _positionManager;
    }

    /// @notice add liqudiity to pool key,
    function addLiquidity(
        PoolKey memory key,
        uint128 amountX,
        uint128 amountY,
        uint24 currentActiveId,
        uint24 numOfBins
    ) internal {
        uint24[] memory binIds = new uint24[](numOfBins);
        uint24 startId = currentActiveId - (numOfBins / 2);
        for (uint256 i; i < numOfBins; i++) {
            binIds[i] = startId;
            startId++;
        }

        uint8 nbBinX; // num of bins to the right
        uint8 nbBinY; // num of bins to the left
        for (uint256 i; i < numOfBins; ++i) {
            if (binIds[i] >= currentActiveId) nbBinX++;
            if (binIds[i] <= currentActiveId) nbBinY++;
        }

        // Equal distribution across all binds
        uint256[] memory distribX = new uint256[](numOfBins);
        uint256[] memory distribY = new uint256[](numOfBins);
        for (uint256 i; i < numOfBins; ++i) {
            uint24 binId = binIds[i];
            distribX[i] = binId >= currentActiveId && nbBinX > 0 ? uint256(1e18 / nbBinX).safe64() : 0;
            distribY[i] = binId <= currentActiveId && nbBinY > 0 ? uint256(1e18 / nbBinY).safe64() : 0;
        }

        IBinFungiblePositionManager.AddLiquidityParams memory params = IBinFungiblePositionManager.AddLiquidityParams({
            poolKey: key,
            amount0: amountX,
            amount1: amountY,
            amount0Min: 0, // note in real world, this should not be 0
            amount1Min: 0, // note in real world, this should not be 0
            activeIdDesired: uint256(currentActiveId),
            idSlippage: 0,
            deltaIds: convertToRelative(binIds, currentActiveId),
            distributionX: distribX,
            distributionY: distribY,
            to: address(this),
            deadline: block.timestamp + 600
        });

        positionManager.addLiquidity(params);
    }

    /// @notice remove liquidity from pool key
    function removeLiquidity(
        PoolKey memory key,
        uint128 amountX,
        uint128 amountY,
        uint24 currentActiveId,
        uint24 numOfBins
    ) internal {
        uint24[] memory binIds = new uint24[](numOfBins);
        uint24 startId = currentActiveId - (numOfBins / 2);
        for (uint256 i; i < numOfBins; i++) {
            binIds[i] = startId;
            startId++;
        }

        uint8 nbBinX; // num of bins to the right
        uint8 nbBinY; // num of bins to the left
        for (uint256 i; i < numOfBins; ++i) {
            if (binIds[i] >= currentActiveId) nbBinX++;
            if (binIds[i] <= currentActiveId) nbBinY++;
        }

        // Equal distribution across all bins
        uint256[] memory distribX = new uint256[](numOfBins);
        uint256[] memory distribY = new uint256[](numOfBins);
        for (uint256 i; i < numOfBins; ++i) {
            uint24 binId = binIds[i];
            distribX[i] = binId >= currentActiveId && nbBinX > 0 ? uint256(1e18 / nbBinX).safe64() : 0;
            distribY[i] = binId <= currentActiveId && nbBinY > 0 ? uint256(1e18 / nbBinY).safe64() : 0;
        }

        IBinFungiblePositionManager.RemoveLiquidityParams memory params = IBinFungiblePositionManager
            .RemoveLiquidityParams({
                poolKey: key,
                amount0Min: 0, // note in real world, this should not be 0
                amount1Min: 0, // note in real world, this should not be 0
                ids: new uint256[](1),
                amounts: new uint256[](1),
                from: address(this),
                to: address(this),
                deadline: block.timestamp + 600
            });

        params.ids[0] = uint256(currentActiveId);
        params.amounts[0] = type(uint256).max;

        positionManager.removeLiquidity(params);
    }

    /// @dev Given list of binIds and activeIds, return the delta ids.
    //       eg. given id: [100, 101, 102] and activeId: 101, return [-1, 0, 1]
    function convertToRelative(
        uint24[] memory absoluteIds,
        uint24 activeId
    ) internal pure returns (int256[] memory relativeIds) {
        relativeIds = new int256[](absoluteIds.length);
        for (uint256 i = 0; i < absoluteIds.length; i++) {
            relativeIds[i] = int256(uint256(absoluteIds[i])) - int256(uint256(activeId));
        }
    }
}
