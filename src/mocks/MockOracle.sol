// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IOracle} from "../interfaces/IOracle.sol";
import {IMarket} from "../interfaces/IMarket.sol";

contract Oracle is IOracle {
    IMarket public market;

    constructor(address _market) {
        market = IMarket(_market);
    }

    function resolveMarket(
        bytes32 proposalId,
        IMarket.Outcome outcome
    ) external override {
        market.resolveMarket(proposalId, outcome);
    }
}
