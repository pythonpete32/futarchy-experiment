// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarket {
    /// @notice Enum to represent the possible outcomes of a market
    enum Outcome {
        Unresolved,
        Yes,
        No
    }

    /// @notice Structure to hold information about each market
    /// @dev Each market is associated with a specific proposal in the DAO
    struct MarketInfo {
        bytes32 proposalId; // Unique identifier of the associated proposal
        bytes32 questionHash; // Hash of the question associated with the proposal
        uint256 creationTime; // Timestamp when the market was created
        uint256 resolutionTime; // Timestamp when the market was resolved
        uint256 tradingPeriod; // Duration for which trading is allowed
        bool resolved; // Whether the market has been resolved
        Outcome outcome; // The final outcome of the market
        uint256 yesShares; // Number of YES shares issued
        uint256 noShares; // Number of NO shares issued
        uint256 yesReserve; // Number of GovernanceTokens in the Yes market
        uint256 noReserve; // Number of GovernanceTokens in the No market
    }

    /// @notice Structure to hold a user's position in a market
    struct Position {
        uint256 yesShares; // Number of YES shares held
        uint256 noShares; // Number of NO shares held
    }

    /// @notice Event emitted when a new market is created
    /// @param proposalId The ID of the proposal associated with the market
    /// @param tradingPeriod The duration of the trading period
    event MarketCreated(bytes32 indexed proposalId, uint256 tradingPeriod);

    /// @notice Event emitted when shares are bought
    /// @param proposalId The ID of the proposal associated with the market
    /// @param trader The address of the trader
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param shareAmount The number of shares bought
    /// @param tokenAmount The amount of governance tokens paid
    event SharesBought(
        bytes32 indexed proposalId, address indexed trader, bool position, uint256 shareAmount, uint256 tokenAmount
    );

    /// @notice Event emitted when shares are sold
    /// @param proposalId The ID of the proposal associated with the market
    /// @param trader The address of the trader
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param shareAmount The number of shares sold
    /// @param tokenAmount The amount of governance tokens received
    event SharesSold(
        bytes32 indexed proposalId, address indexed trader, bool position, uint256 shareAmount, uint256 tokenAmount
    );

    /// @notice Event emitted when a market is resolved
    /// @param proposalId The ID of the proposal associated with the market
    /// @param outcome The final outcome of the market
    event MarketResolved(bytes32 indexed proposalId, Outcome outcome);

    /// @notice Event emitted when the oracle is updated
    /// @param newOracle address of the new oracle
    event OracleUpdated(address newOracle);

    /// @notice Event emitted when winnings are claimed
    /// @param proposalId The ID of the proposal associated with the market
    /// @param trader The address of the user claiming winnings
    /// @param amount The amount of winnings claimed
    event WinningsClaimed(bytes32 indexed proposalId, address indexed trader, uint256 amount);

    function createMarket(bytes32 proposalId, bytes32 questionHash, uint256 tradingPeriod) external;

    function buyShares(bytes32 proposalId, bool position, uint256 amount) external;

    function sellShares(bytes32 proposalId, bool position, uint256 shareAmount) external;

    function resolveMarket(bytes32 proposalId, Outcome outcome) external;

    function claimWinnings(bytes32 proposalId) external;

    function getPosition(bytes32 proposalId, address trader) external view returns (Position memory);

    function getMarketInfo(bytes32 proposalId) external view returns (MarketInfo memory);
}
