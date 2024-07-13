// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockOracle} from "./MockOracle.sol";

/// @title Implied Odds Helper Contract
/// @notice This contract calculates the implied odds for each round and determines the liquidity to be distributed in each pool
contract ImpliedOddsHelper {
    /// @notice Oracle instance to fetch match data
    MockOracle public oracle;

    /// @notice Constructor to initialize the oracle instance
    /// @param oracleAddress The address of the MockOracle contract
    constructor(address oracleAddress) {
        oracle = MockOracle(oracleAddress);
    }

    /// @notice Calculates the new liquidity distribution based on the current total liquidity and match data
    /// @param currentTotalLiquidity The total liquidity available for distribution
    /// @return englandLiquidity The calculated liquidity for England
    /// @return spainLiquidity The calculated liquidity for Spain
    /// @return drawLiquidity The calculated liquidity for a draw
    function calculateNewLiquidity(
        uint256 currentTotalLiquidity
    ) external view returns (uint256 englandLiquidity, uint256 spainLiquidity, uint256 drawLiquidity) {
        // Fetch the latest match data from the oracle
        MockOracle.MatchData memory matchData = oracle.getMatchData(type(uint256).max);

        // Base liquidity amount (example value)
        uint256 baseLiquidity = currentTotalLiquidity;
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

        // Calculate liquidity based on odds and normalize them
        englandLiquidity = (baseLiquidity * uint256(englandOdds)) / totalOdds;
        spainLiquidity = (baseLiquidity * uint256(spainOdds)) / totalOdds;
        drawLiquidity = (baseLiquidity * uint256(drawOdds)) / totalOdds;
    }
}
