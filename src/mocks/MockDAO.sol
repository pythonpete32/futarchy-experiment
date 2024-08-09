// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDAO} from "../interfaces/IDAO.sol";

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
