// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDAO {
    struct Proposal {
        bytes32 id;
        address proposer;
        string description;
        uint256 votingEndTime;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
    }

    function createProposal(string memory description, uint256 votingPeriod) external returns (bytes32);
    function vote(bytes32 proposalId, bool support) external;
    function executeProposal(bytes32 proposalId) external;
    function getProposal(bytes32 proposalId) external view returns (Proposal memory);
}