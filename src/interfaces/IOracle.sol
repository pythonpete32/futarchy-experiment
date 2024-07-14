// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IMarket} from "./IMarket.sol";

interface IOracle {
    function resolveMarket(
        bytes32 proposalId,
        IMarket.Outcome outcome
    ) external;
}
