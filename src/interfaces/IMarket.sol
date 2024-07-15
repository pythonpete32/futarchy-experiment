// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
        uint256 creationTime; // Timestamp when the market was created
        uint256 resolutionTime; // Timestamp when the market was resolved
        uint256 tradingPeriod; // Duration for which trading is allowed
        bool resolved; // Whether the market has been resolved
        Outcome outcome; // The final outcome of the market
        uint256 virtualReserve; // Virtual liquidity to control price sensitivity
        uint256 actualYesShares; // Number of YES shares issued
        uint256 actualNoShares; // Number of NO shares issued
        uint256 totalFeesCollected; // Total fees collected from trades
    }

    /// @notice Structure to hold a user's position in a market
    struct Position {
        uint256 yesShares; // Number of YES shares held
        uint256 noShares; // Number of NO shares held
    }

    /// @notice Event emitted when a new market is created
    /// @param proposalId The ID of the proposal associated with the market
    /// @param virtualReserve The initial virtual reserve set for the market
    /// @param tradingPeriod The duration of the trading period
    event MarketCreated(
        bytes32 indexed proposalId,
        uint256 virtualReserve,
        uint256 tradingPeriod
    );

    /// @notice Event emitted when shares are bought
    /// @param proposalId The ID of the proposal associated with the market
    /// @param trader The address of the trader
    /// @param isYes Whether YES shares were bought (false for NO shares)
    /// @param shareAmount The number of shares bought
    /// @param tokenAmount The amount of governance tokens paid
    event SharesBought(
        bytes32 indexed proposalId,
        address indexed trader,
        bool isYes,
        uint256 shareAmount,
        uint256 tokenAmount
    );

    /// @notice Event emitted when shares are sold
    /// @param proposalId The ID of the proposal associated with the market
    /// @param trader The address of the trader
    /// @param isYes Whether YES shares were sold (false for NO shares)
    /// @param shareAmount The number of shares sold
    /// @param tokenAmount The amount of governance tokens received
    event SharesSold(
        bytes32 indexed proposalId,
        address indexed trader,
        bool isYes,
        uint256 shareAmount,
        uint256 tokenAmount
    );

    /// @notice Event emitted when a market is resolved
    /// @param proposalId The ID of the proposal associated with the market
    /// @param outcome The final outcome of the market
    event MarketResolved(bytes32 indexed proposalId, Outcome outcome);

    function createMarket(
        bytes32 proposalId,
        uint256 virtualReserve,
        uint256 tradingPeriod
    ) external;

    function buyShares(bytes32 proposalId, bool isYes, uint256 amount) external;

    function sellShares(
        bytes32 proposalId,
        bool isYes,
        uint256 shareAmount
    ) external;

    function resolveMarket(bytes32 proposalId, Outcome outcome) external;

    function claimWinnings(bytes32 proposalId) external;

    function getYesPrice(bytes32 proposalId) external view returns (uint256);

    function getPosition(
        bytes32 proposalId,
        address trader
    ) external view returns (Position memory);

    function getMarketInfo(
        bytes32 proposalId
    ) external view returns (MarketInfo memory);
}
