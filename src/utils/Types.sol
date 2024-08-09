// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract Types {
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
}
