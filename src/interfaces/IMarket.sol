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

    function createMarket(bytes32 proposalId, uint256 tradingPeriod) external;
    function buy(bytes32 proposalId, bool outcome, uint256 amount) external;
    function sell(bytes32 proposalId, bool outcome, uint256 amount) external;
    function resolveMarket(bytes32 proposalId, Outcome outcome) external;
    function claimWinnings(bytes32 proposalId) external;
    function getPosition(bytes32 proposalId, address trader) external view returns (Position memory);
}
