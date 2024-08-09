// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Types} from "../utils/Types.sol";

interface IMarket {
    function createMarket(bytes32 proposalId, bytes32 questionHash, uint256 tradingPeriod) external;

    function buyShares(bytes32 proposalId, bool position, uint256 amount) external;

    function sellShares(bytes32 proposalId, bool position, uint256 shareAmount) external;

    function resolveMarket(bytes32 proposalId, Types.Outcome outcome) external;

    function claimWinnings(bytes32 proposalId) external;

    function getPosition(bytes32 proposalId, address trader) external view returns (Types.Position memory);

    function getMarketInfo(bytes32 proposalId) external view returns (Types.MarketInfo memory);
}
