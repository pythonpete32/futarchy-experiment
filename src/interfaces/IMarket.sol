// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMarket {
    enum Outcome {
        Unresolved,
        Yes,
        No
    }

    struct Position {
        uint256 yesShares;
        uint256 noShares;
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

    function createMarket(bytes32 proposalId, uint256 tradingPeriod) external;

    function buy(bytes32 proposalId, bool outcome, uint256 amount) external;

    function sell(bytes32 proposalId, bool outcome, uint256 amount) external;

    function resolveMarket(bytes32 proposalId, Outcome outcome) external;

    function claimWinnings(bytes32 proposalId) external;

    function getPosition(
        bytes32 proposalId,
        address trader
    ) external view returns (Position memory);
}
