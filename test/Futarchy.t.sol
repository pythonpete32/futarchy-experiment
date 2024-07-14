// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IDAO, DAO} from "../src/mocks/MockDAO.sol";
import {IMarket, Market} from "../src/mocks/MockMarket.sol";
import {Oracle, IOracle} from "../src/mocks/MockOracle.sol";

contract FutarchyTest is Test {
    IDAO dao;
    IMarket market;
    IOracle oracle;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        dao = new DAO();
        market = new Market();
        oracle = new Oracle(address(market));
    }

    function testCreateProposal() public {
        vm.prank(alice);
        bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);
        IDAO.Proposal memory proposal = dao.getProposal(proposalId);
        assertEq(proposal.proposer, alice);
        assertEq(proposal.description, "Test Proposal");
        assertEq(proposal.votingEndTime, block.timestamp + 1 days);
    }

    function testVoting() public {
        vm.prank(alice);
        bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);

        vm.prank(bob);
        dao.vote(proposalId, true);

        IDAO.Proposal memory proposal = dao.getProposal(proposalId);
        assertEq(proposal.yesVotes, 1);
        assertEq(proposal.noVotes, 0);
    }

    function testMarketCreation() public {
        vm.prank(alice);
        bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);

        market.createMarket(proposalId, 2 days);

        // Add assertions to check if the market was created correctly
    }

    function testBuyingShares() public {
        vm.prank(alice);
        bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);
        market.createMarket(proposalId, 2 days);

        vm.prank(bob);
        market.buy(proposalId, true, 100);

        IMarket.Position memory position = market.getPosition(proposalId, bob);
        assertEq(position.yesShares, 100);
        assertEq(position.noShares, 0);
    }

    function testMarketResolution() public {
        vm.prank(alice);
        bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);
        market.createMarket(proposalId, 2 days);

        vm.prank(address(oracle));
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        // Add assertions to check if the market was resolved correctly
    }

    // Add more tests for other functions and edge cases
}
