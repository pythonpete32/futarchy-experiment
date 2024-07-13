// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/interfaces/IDAO.sol";
import "../src/interfaces/IMarket.sol";
import "../src/interfaces/IOracle.sol";


contract DAO is IDAO {
    mapping(bytes32 => Proposal) public proposals;

    function createProposal(string memory description, uint256 votingPeriod) external override returns (bytes32) {
        bytes32 proposalId = keccak256(abi.encodePacked(description, block.timestamp, msg.sender));
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            votingEndTime: block.timestamp + votingPeriod,
            executed: false,
            yesVotes: 0,
            noVotes: 0
        });
        return proposalId;
    }

    function vote(bytes32 proposalId, bool support) external override {
        require(block.timestamp < proposals[proposalId].votingEndTime, "Voting period has ended");
        if (support) {
            proposals[proposalId].yesVotes += 1;
        } else {
            proposals[proposalId].noVotes += 1;
        }
    }

    function executeProposal(bytes32 proposalId) external override {
        require(block.timestamp >= proposals[proposalId].votingEndTime, "Voting period has not ended");
        require(!proposals[proposalId].executed, "Proposal already executed");
        proposals[proposalId].executed = true;
        // Implementation of proposal execution would go here
    }

    function getProposal(bytes32 proposalId) external view override returns (Proposal memory) {
        return proposals[proposalId];
    }
}

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

contract Oracle is IOracle {
    IMarket public market;

    constructor(address _market) {
        market = IMarket(_market);
    }

    function resolveMarket(bytes32 proposalId, IMarket.Outcome outcome) external override {
        market.resolveMarket(proposalId, outcome);
    }
}