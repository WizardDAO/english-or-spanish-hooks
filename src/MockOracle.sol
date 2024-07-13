pragma solidity ^0.8.0;

/**
 * @title MockOracle
 * @author
 * @notice
 * @dev This contract is used to simulate the match data update
 * There will be admin functions to increase the goal count of either side, start a match, and end a match
 * There will be a match counter
 */
contract MockOracle {
    // Enum representing possible match outcomes
    enum MatchOutcome {
        NotStarted,
        EnglandWins,
        SpainWins,
        Draw
    }

    // Struct representing match data
    struct MatchData {
        MatchOutcome outcome; // Outcome of the match
        uint256 goalsEngland; // Goals scored by England
        uint256 goalsSpain; // Goals scored by Spain
        bool isMatchFinished; // Flag indicating if the match is finished
    }

    uint256 public matchCounter; // Match counter
    mapping(uint256 => MatchData) public matchData; // Mapping from match counter to match data

    // Event emitted when a match is started
    event MatchStarted(uint256 matchId);

    // Event emitted when a goal is scored
    event GoalScored(uint256 matchId, string team);

    // Event emitted when a match is ended
    event MatchEnded(uint256 matchId, MatchOutcome outcome);

    // Function to start a new match, Call in init in EnglishOrSpanish
    function startMatch() external {
        matchCounter++;
        matchData[matchCounter] = MatchData({
            outcome: MatchOutcome.NotStarted,
            goalsEngland: 0,
            goalsSpain: 0,
            isMatchFinished: false
        });
        emit MatchStarted(matchCounter);
    }

    // Function to increase the goal count for England
    function increaseGoalsEngland(uint256 matchId) external {
        require(!matchData[matchId].isMatchFinished, "Match is already finished");
        matchData[matchId].goalsEngland++;
        emit GoalScored(matchId, "England");
    }

    // Function to increase the goal count for Spain
    function increaseGoalsSpain(uint256 matchId) external {
        require(!matchData[matchId].isMatchFinished, "Match is already finished");
        matchData[matchId].goalsSpain++;
        emit GoalScored(matchId, "Spain");
    }

    // Function to end a match and set the outcome
    function endMatch(uint256 matchId) external {
        require(!matchData[matchId].isMatchFinished, "Match is already finished");
        matchData[matchId].isMatchFinished = true;

        if (matchData[matchId].goalsEngland > matchData[matchId].goalsSpain) {
            matchData[matchId].outcome = MatchOutcome.EnglandWins;
        } else if (matchData[matchId].goalsSpain > matchData[matchId].goalsEngland) {
            matchData[matchId].outcome = MatchOutcome.SpainWins;
        } else {
            matchData[matchId].outcome = MatchOutcome.Draw;
        }

        emit MatchEnded(matchId, matchData[matchId].outcome);
    }

    // Function to increase the current goal count for England
    function increaseCurrentGoalsEngland() external {
        require(matchCounter > 0, "No match has been started");
        require(!matchData[matchCounter].isMatchFinished, "Match is already finished");
        matchData[matchCounter].goalsEngland++;
        emit GoalScored(matchCounter, "England");
    }

    // Function to increase the current goal count for Spain
    function increaseCurrentGoalsSpain() external {
        require(matchCounter > 0, "No match has been started");
        require(!matchData[matchCounter].isMatchFinished, "Match is already finished");
        matchData[matchCounter].goalsSpain++;
        emit GoalScored(matchCounter, "Spain");
    }

    // Function to get match data by match ID
    function getMatchData(uint256 matchId) external view returns (MatchData memory) {
        return matchData[matchId];
    }

    // Add get current match data function
    function getCurrentMatchData() external view returns (MatchData memory) {
        return matchData[matchCounter];
    }
}
