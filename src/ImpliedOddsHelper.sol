// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockOracle} from "./MockOracle.sol";
import {ln, unwrap, wrap, UD60x18} from "@prb/math/src/UD60x18.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {IBinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/interfaces/IBinFungiblePositionManager.sol";
import {SafeCast} from "@pancakeswap/v4-core/src/pool-bin/libraries/math/SafeCast.sol";

/// @title Implied Odds Helper Contract
/// @notice This contract calculates the implied odds for each round and determines the liquidity to be distributed in each pool
contract ImpliedOddsHelper {
    /// @notice Oracle instance to fetch match data
    MockOracle public oracle;
    uint256 private constant UNIT = 10 ** 18;
    uint256 private constant baseId = 8388608;

    /// @notice Constructor to initialize the oracle instance
    /// @param oracleAddress The address of the MockOracle contract
    constructor(MockOracle oracleAddress) {
        oracle = oracleAddress;
    }

    /**
     * @notice Calculates the activeId given a price.
     * @param price The price for which to calculate the activeId (in 60.18-decimal fixed-point format).
     * @return activeId The calculated activeId.
     */
    function getActiveIdFromPrice(uint256 price) public pure returns (uint24) {
        require(price > 0, "Price must be greater than zero");

        // Wrap the price as UD60x18
        UD60x18 priceUD = wrap(price);

        // Calculate the natural log of the price
        UD60x18 lnPrice = ln(priceUD);

        // Calculate the natural log of 1.01
        UD60x18 lnBase = ln(wrap((101 * UNIT) / 100)); // ln(1.01)

        // Calculate activeId using the formula: activeId = ln(price) / ln(1.01) + baseId
        uint24 activeId = uint24((unwrap(lnPrice) * UNIT) / unwrap(lnBase) + baseId);

        return activeId;
    }

    /// @notice Calculates the new liquidity distribution based on the current total liquidity and match data
    /// @return englandBin The calculated bin for England
    /// @return spainBin The calculated bin for Spain
    /// @return drawBin The calculated bin for a draw
    function calculateNewBins() public view returns (uint24 englandBin, uint24 spainBin, uint24 drawBin) {
        // Fetch the latest match data from the oracle
        MockOracle.MatchData memory matchData = oracle.getMatchData(type(uint256).max);

        // Calculate odds based on goals, ensuring they stay within valid bounds
        int256 englandOdds = int256(35 + (matchData.goalsEngland * 15) - (matchData.goalsSpain * 15));
        int256 spainOdds = int256(35 + (matchData.goalsSpain * 15) - (matchData.goalsEngland * 15));
        int256 drawOdds = 100 - englandOdds - spainOdds;

        // Ensure odds are non-negative and do not exceed 100%
        if (englandOdds < 0) englandOdds = 0;
        if (spainOdds < 0) spainOdds = 0;
        if (drawOdds < 0) drawOdds = 0;

        uint256 totalOdds = uint256(englandOdds + spainOdds + drawOdds);
        require(totalOdds > 0, "Total odds must be greater than 0");

        // Normalize the odds to 60.18 decimal fixed-point format
        uint256 englandOddsScaled = (uint256(englandOdds) * UNIT) / totalOdds;
        uint256 spainOddsScaled = (uint256(spainOdds) * UNIT) / totalOdds;
        uint256 drawOddsScaled = (uint256(drawOdds) * UNIT) / totalOdds;

        // Calculate the active bin IDs based on the normalized odds
        englandBin = (getActiveIdFromPrice(englandOddsScaled));
        spainBin = (getActiveIdFromPrice(spainOddsScaled));
        drawBin = (getActiveIdFromPrice(drawOddsScaled));
    }
}
