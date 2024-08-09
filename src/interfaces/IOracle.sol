// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Types} from "../utils/Types.sol";

interface IOracle {
    function resolveMarket(address market, bytes32 proposalId, Types.Outcome outcome) external;
}
