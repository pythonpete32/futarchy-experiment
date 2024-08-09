// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOracle} from "../interfaces/IOracle.sol";
import {Types} from "../utils/Types.sol";

contract MockOracle is IOracle {
    function resolveMarket(address market, bytes32 proposalId, Types.Outcome outcome) external {
        // Call the resolveMarket function on the FutarchyMarket contract
        (bool success,) = market.call(abi.encodeWithSignature("resolveMarket(bytes32,uint8)", proposalId, outcome));
        require(success, "Failed to resolve market");
    }
}
