// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import {Types} from "./Types.sol";

contract Events {
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
    event MarketResolved(bytes32 indexed proposalId, Types.Outcome outcome);

    /// @notice Event emitted when the oracle is updated
    /// @param newOracle address of the new oracle
    event OracleUpdated(address newOracle);

    /// @notice Event emitted when winnings are claimed
    /// @param proposalId The ID of the proposal associated with the market
    /// @param trader The address of the user claiming winnings
    /// @param amount The amount of winnings claimed
    event WinningsClaimed(bytes32 indexed proposalId, address indexed trader, uint256 amount);
}
