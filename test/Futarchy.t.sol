// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IDAO, DAO} from "../src/mocks/MockDAO.sol";
import {IMarket, Market} from "../src/mocks/MockMarket.sol";
import {Oracle} from "../src/mocks/MockOracle.sol";
import {MockGovernanceToken} from "../src/mocks/MockGovernanceToken.sol";

contract FutarchyTest is Test {
    IDAO dao;
    IMarket market;
    MockGovernanceToken governanceToken;
    address oracle = address(0x04ac1e);

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        governanceToken = new MockGovernanceToken();
        dao = new DAO();
        oracle = address(0x2);
        market = new Market(
            address(governanceToken),
            address(dao),
            address(oracle)
        );

        governanceToken.mint(alice, 1000000 * 10 ** 18);
        governanceToken.mint(bob, 1000000 * 10 ** 18);
        governanceToken.mint(charlie, 1000000 * 10 ** 18);

        vm.prank(alice);
        governanceToken.approve(address(market), type(uint256).max);
        vm.prank(bob);
        governanceToken.approve(address(market), type(uint256).max);
        vm.prank(charlie);
        governanceToken.approve(address(market), type(uint256).max);
    }

    function testCreateProposal() public {
        vm.prank(alice);
        bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);
        IDAO.Proposal memory proposal = dao.getProposal(proposalId);
        assertEq(proposal.proposer, alice);
        assertEq(proposal.description, "Test Proposal");
        assertEq(proposal.votingEndTime, block.timestamp + 1 days);
    }

    function testCreateMarket() public {
        bytes32 proposalId = _createProposal();

        vm.prank(address(dao));
        market.createMarket(proposalId, 1000 * 10 ** 18, 2 days);

        IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
        assertEq(marketInfo.proposalId, proposalId);
        assertEq(marketInfo.tradingPeriod, 2 days);
        assertEq(marketInfo.virtualReserve, 1000 * 10 ** 18);
        assertEq(marketInfo.resolved, false);
    }

    function testBuyShares() public {
        bytes32 proposalId = _createProposalAndMarket();

        vm.prank(bob);
        market.buyShares(proposalId, true, 100 * 10 ** 18);

        IMarket.Position memory position = market.getPosition(proposalId, bob);
        assertGt(position.yesShares, 0);
        assertEq(position.noShares, 0);

        uint256 yesPrice = market.getYesPrice(proposalId);
        assertGt(yesPrice, 500000); // Price should be higher than 50%
    }

    function testSellShares() public {
        bytes32 proposalId = _createProposalAndMarket();

        vm.startPrank(bob);
        market.buyShares(proposalId, true, 100 * 10 ** 18);
        uint256 initialYesShares = market
            .getPosition(proposalId, bob)
            .yesShares;
        market.sellShares(proposalId, true, initialYesShares / 2);
        vm.stopPrank();

        IMarket.Position memory position = market.getPosition(proposalId, bob);
        assertEq(position.yesShares, initialYesShares / 2);
    }

    function testMarketResolution() public {
        bytes32 proposalId = _createProposalAndMarket();

        vm.warp(block.timestamp + 2 days);

        vm.prank(address(oracle));
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
        assertTrue(marketInfo.resolved);
        assertEq(uint(marketInfo.outcome), uint(IMarket.Outcome.Yes));
    }

    function testClaimWinnings() public {
        bytes32 proposalId = _createProposalAndMarket();

        vm.prank(bob);
        market.buyShares(proposalId, true, 100 * 10 ** 18);

        vm.prank(charlie);
        market.buyShares(proposalId, false, 100 * 10 ** 18);

        vm.warp(block.timestamp + 2 days);

        vm.prank(address(oracle));
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        uint256 bobBalanceBefore = governanceToken.balanceOf(bob);

        vm.prank(bob);
        market.claimWinnings(proposalId);

        uint256 bobBalanceAfter = governanceToken.balanceOf(bob);
        assertGt(bobBalanceAfter, bobBalanceBefore);
    }

    function testGetYesPrice() public {
        bytes32 proposalId = _createProposalAndMarket();

        uint256 initialPrice = market.getYesPrice(proposalId);
        assertEq(initialPrice, 500000); // 50% initial price

        vm.prank(bob);
        market.buyShares(proposalId, true, 100 * 10 ** 18);

        uint256 newPrice = market.getYesPrice(proposalId);
        assertGt(newPrice, initialPrice);
    }

    function _createProposal() internal returns (bytes32) {
        vm.prank(alice);
        return dao.createProposal("Test Proposal", 1 days);
    }

    function _createProposalAndMarket() internal returns (bytes32) {
        bytes32 proposalId = _createProposal();
        vm.prank(address(dao));
        market.createMarket(proposalId, 1000 * 10 ** 18, 2 days);
        return proposalId;
    }
}
