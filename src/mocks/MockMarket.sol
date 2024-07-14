// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IMarket} from "../interfaces/IMarket.sol";

contract Market is IMarket {
    mapping(bytes32 => mapping(address => Position)) public positions;
    mapping(bytes32 => Outcome) public outcomes;

    function createMarket(bytes32 proposalId, uint256 tradingPeriod) external override {
        // In a real implementation, we would store the trading period and use it
        // This mock version doesn't use the tradingPeriod parameter
    }

    function buy(bytes32 proposalId, bool outcome, uint256 amount) external override {
        if (outcome) {
            positions[proposalId][msg.sender].yesShares += amount;
        } else {
            positions[proposalId][msg.sender].noShares += amount;
        }
    }

    function sell(bytes32 proposalId, bool outcome, uint256 amount) external override {
        if (outcome) {
            require(positions[proposalId][msg.sender].yesShares >= amount, "Insufficient shares");
            positions[proposalId][msg.sender].yesShares -= amount;
        } else {
            require(positions[proposalId][msg.sender].noShares >= amount, "Insufficient shares");
            positions[proposalId][msg.sender].noShares -= amount;
        }
    }

    function resolveMarket(bytes32 proposalId, Outcome outcome) external override {
        outcomes[proposalId] = outcome;
    }

    function claimWinnings(bytes32 proposalId) external override {
        require(outcomes[proposalId] != Outcome.Unresolved, "Market not resolved");
        // In a real implementation, we would transfer winnings here
        delete positions[proposalId][msg.sender];
    }

    function getPosition(bytes32 proposalId, address trader) external view override returns (Position memory) {
        return positions[proposalId][trader];
    }
}
