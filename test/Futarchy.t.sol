// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DAO} from "../src/mocks/MockDAO.sol";
import {IMarket, FutarchyMarket} from "../src/FutarchyMarket.sol";
import {MockOracle, IOracle} from "../src/mocks/MockOracle.sol";
import {MockGovernanceToken} from "../src/mocks/MockGovernanceToken.sol";

abstract contract FutarchyMarketTestBase is Test {
    FutarchyMarket market;
    MockGovernanceToken governanceToken;
    DAO dao;
    IOracle oracle;

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public virtual {
        governanceToken = new MockGovernanceToken();
        dao = new DAO();
        oracle = IOracle(new MockOracle());

        market = new FutarchyMarket(address(governanceToken), address(dao), address(oracle));

        governanceToken.mint(alice, 1000 * 10 ** 18);
        governanceToken.mint(bob, 1000 * 10 ** 18);
        governanceToken.mint(charlie, 1000 * 10 ** 18);
        governanceToken.mint(address(dao), 10000 * 10 ** 18);

        vm.prank(alice);
        governanceToken.approve(address(market), type(uint256).max);
        vm.prank(bob);
        governanceToken.approve(address(market), type(uint256).max);
        vm.prank(charlie);
        governanceToken.approve(address(market), type(uint256).max);
        vm.prank(address(dao));
        governanceToken.approve(address(market), type(uint256).max);
    }
}

contract CreateMarketTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
    }

    function test_RevertWhen_CallerIsNotDAO() external {
        bytes32 proposalId = keccak256("proposal1");
        bytes32 questionHash = keccak256("some ipfs hash to a question");

        uint256 tradingPeriod = 7 days;

        vm.prank(alice);
        vm.expectRevert("Caller is not the DAO");
        market.createMarket(proposalId, questionHash, tradingPeriod);
    }

    function test_RevertWhen_MarketAlreadyExists() external {
        bytes32 proposalId = keccak256("proposal1");
        bytes32 questionHash = keccak256("some ipfs hash to a question");

        uint256 tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, questionHash, tradingPeriod);
        vm.prank(address(dao));
        vm.expectRevert("Market already exists");
        market.createMarket(proposalId, questionHash, tradingPeriod);
    }

    function test_WhenCallerIsDAOAndMarketDoesntExist() external {
        bytes32 proposalId = keccak256(abi.encode(block.timestamp));
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        uint256 tradingPeriod = 7 days;

        vm.prank(address(dao));
        vm.expectEmit(true, true, true, true);
        emit IMarket.MarketCreated(proposalId, tradingPeriod);
        market.createMarket(proposalId, questionHash, tradingPeriod);
        IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
        assertEq(marketInfo.proposalId, proposalId, "ProposalID not saved correctly");
        assertEq(marketInfo.tradingPeriod, tradingPeriod);
        assertEq(marketInfo.creationTime, block.timestamp);
        assertEq(marketInfo.resolved, false);
        assertEq(uint256(marketInfo.outcome), uint256(IMarket.Outcome.Unresolved));
        assertEq(marketInfo.yesShares, FutarchyMarket(market).INITIAL_LIQUIDITY());
        assertEq(marketInfo.noShares, FutarchyMarket(market).INITIAL_LIQUIDITY());
        assertEq(marketInfo.yesReserve, FutarchyMarket(market).INITIAL_LIQUIDITY());
        assertEq(marketInfo.noReserve, FutarchyMarket(market).INITIAL_LIQUIDITY());
    }
}

contract BuySharesTest is FutarchyMarketTestBase {
    bytes32 proposalId;
    uint256 tradingPeriod;

    function setUp() public override {
        super.setUp();
        proposalId = keccak256("testProposal");
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, questionHash, tradingPeriod);
    }

    function test_RevertWhen_MarketDoesntExist() external {
        bytes32 nonExistentProposalId = keccak256("nonExistentProposal");
        vm.prank(alice);
        vm.expectRevert("Market does not exist");
        market.buyShares(nonExistentProposalId, true, 100 * 10 ** 18);
    }

    function test_RevertWhen_TradingPeriodHasEnded() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(alice);
        vm.expectRevert("Trading period has ended");
        market.buyShares(proposalId, true, 100 * 10 ** 18);
    }

    function test_RevertWhen_MarketIsAlreadyResolved() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        oracle.resolveMarket(address(market), proposalId, IMarket.Outcome.Yes);

        vm.prank(alice);
        vm.expectRevert("Market is already resolved");
        market.buyShares(proposalId, true, 100 * 10 ** 18);
    }

    function test_RevertWhen_UserDoesntHaveEnoughTokens() external {
        uint256 excessiveAmount = 2000 * 10 ** 18; // Alice only has 1000 tokens
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, alice, 1000 * 10 ** 18, excessiveAmount
            )
        );
        market.buyShares(proposalId, true, excessiveAmount);
    }

    function test_WhenAllConditionsAreMet() external {
        uint256 buyAmount = 10 * 10 ** 18;
        (uint256 sharesToMint,) = market.getSharesOutAmount(proposalId, true, buyAmount);
        uint256 aliceBalanceBefore = governanceToken.balanceOf(alice);
        uint256 marketBalanceBefore = governanceToken.balanceOf(address(market));
        IMarket.MarketInfo memory marketInfoBefore = market.getMarketInfo(proposalId);
        uint256 sharesBefore = marketInfoBefore.yesShares;

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);

        emit IMarket.SharesBought(proposalId, alice, true, sharesToMint, buyAmount);
        market.buyShares(proposalId, true, buyAmount);

        // Check token transfer
        assertEq(governanceToken.balanceOf(alice), aliceBalanceBefore - buyAmount, "Incorrect token transfer from user");
        assertEq(
            governanceToken.balanceOf(address(market)),
            marketBalanceBefore + buyAmount,
            "Incorrect token transfer to market"
        );

        // Check share minting and market update
        IMarket.Position memory alicePosition = market.getPosition(proposalId, alice);
        assertGt(alicePosition.yesShares, 0, "Shares not minted to user");

        IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
        assertEq(marketInfo.yesShares - sharesBefore, alicePosition.yesShares, "Market shares not updated correctly");
        assertEq(
            marketInfo.yesReserve,
            FutarchyMarket(market).INITIAL_LIQUIDITY() + buyAmount,
            "Market reserve not updated correctly"
        );
    }
}

contract SellSharesTest is FutarchyMarketTestBase {
    bytes32 proposalId;
    uint256 tradingPeriod;
    uint256 constant INITIAL_BALANCE = 1000 * 10 ** 18;
    uint256 constant BUY_AMOUNT = 100 * 10 ** 18;

    function setUp() public override {
        super.setUp();
        proposalId = keccak256("testProposal");
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, questionHash, tradingPeriod);
        // Buy some shares for testing
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT);
    }

    function test_RevertWhen_MarketDoesntExist() external {
        bytes32 nonExistentProposalId = keccak256("nonExistentProposal");
        vm.prank(alice);
        vm.expectRevert("Market does not exist");
        market.sellShares(nonExistentProposalId, true, 10 * 10 ** 18);
    }

    function test_RevertWhen_TradingPeriodHasEnded() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(alice);
        vm.expectRevert("Trading period has ended");
        market.sellShares(proposalId, true, 10 * 10 ** 18);
    }

    function test_RevertWhen_MarketIsAlreadyResolved() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        oracle.resolveMarket(address(market), proposalId, IMarket.Outcome.Yes);

        vm.prank(alice);
        vm.expectRevert("Market is already resolved");
        market.sellShares(proposalId, true, 10 * 10 ** 18);
    }

    function test_RevertWhen_UserDoesntHaveEnoughShares() external {
        IMarket.Position memory alicePosition = market.getPosition(proposalId, alice);
        uint256 excessiveAmount = alicePosition.yesShares + 1;

        vm.prank(alice);
        vm.expectRevert("Insufficient YES shares");
        market.sellShares(proposalId, true, excessiveAmount);
    }

    function test_WhenAllConditionsAreMet() external {
        IMarket.Position memory alicePositionBefore = market.getPosition(proposalId, alice);
        uint256 sellAmount = alicePositionBefore.yesShares / 2;
        uint256 aliceBalanceBefore = governanceToken.balanceOf(alice);
        IMarket.MarketInfo memory marketInfoBefore = market.getMarketInfo(proposalId);

        (uint256 expectedTokensToReceive,) = market.getTokensOutAmount(proposalId, true, sellAmount);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IMarket.SharesSold(proposalId, alice, true, sellAmount, expectedTokensToReceive);
        market.sellShares(proposalId, true, sellAmount);

        // Check token transfer
        uint256 aliceBalanceAfter = governanceToken.balanceOf(alice);
        assertEq(aliceBalanceAfter, aliceBalanceBefore + expectedTokensToReceive, "Incorrect token transfer to user");

        // Check share burning and market update
        IMarket.Position memory alicePositionAfter = market.getPosition(proposalId, alice);
        assertEq(
            alicePositionAfter.yesShares, alicePositionBefore.yesShares - sellAmount, "Shares not burned from user"
        );

        IMarket.MarketInfo memory marketInfoAfter = market.getMarketInfo(proposalId);
        assertEq(
            marketInfoAfter.yesShares, marketInfoBefore.yesShares - sellAmount, "Market shares not updated correctly"
        );
        assertEq(
            marketInfoAfter.yesReserve,
            marketInfoBefore.yesReserve - expectedTokensToReceive,
            "Market reserve not updated correctly"
        );
    }

    function test_CorrectTokenCalculation() external {
        IMarket.Position memory alicePosition = market.getPosition(proposalId, alice);
        uint256 sellAmount = alicePosition.yesShares / 2;

        (uint256 tokensToReceive, uint256 effectivePrice) = market.getTokensOutAmount(proposalId, true, sellAmount);

        // Ensure tokensToReceive is not zero
        assertGt(tokensToReceive, 0, "Tokens to receive should be greater than zero");

        // Ensure effectivePrice is reasonable (not zero or extremely high)
        assertGt(effectivePrice, 0, "Effective price should be greater than zero");
        assertLt(effectivePrice, 1e36, "Effective price should be less than 1e36");

        // Perform the actual sell
        vm.prank(alice);
        market.sellShares(proposalId, true, sellAmount);

        // Check if the received amount matches the calculated amount
        uint256 aliceBalanceAfter = governanceToken.balanceOf(alice);
        assertEq(
            aliceBalanceAfter,
            INITIAL_BALANCE - BUY_AMOUNT + tokensToReceive,
            "Received token amount doesn't match calculated amount"
        );
    }
}

contract ResolveMarketTest is FutarchyMarketTestBase {
    bytes32 proposalId;
    uint256 tradingPeriod;

    function setUp() public override {
        super.setUp();
        proposalId = keccak256("testProposal");
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, questionHash, tradingPeriod);
    }

    function test_RevertWhen_CallerIsNotOracle() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(alice);
        vm.expectRevert("Caller is not the oracle");
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);
    }

    function test_RevertWhen_MarketDoesntExist() external {
        bytes32 nonExistentProposalId = keccak256("nonExistentProposal");
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(address(oracle));
        vm.expectRevert("Market does not exist");
        market.resolveMarket(nonExistentProposalId, IMarket.Outcome.Yes);
    }

    function test_RevertWhen_MarketIsAlreadyResolved() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(address(oracle));
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        vm.prank(address(oracle));
        vm.expectRevert("Market is already resolved");
        market.resolveMarket(proposalId, IMarket.Outcome.No);
    }

    function test_RevertWhen_TradingPeriodHasntEnded() external {
        vm.warp(block.timestamp + tradingPeriod - 1);
        vm.prank(address(oracle));
        vm.expectRevert("Trading period has not ended");
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);
    }

    function test_WhenAllConditionsAreMet() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(address(oracle));

        vm.expectEmit(true, true, true, true);
        emit IMarket.MarketResolved(proposalId, IMarket.Outcome.Yes);

        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        IMarket.MarketInfo memory resolvedMarket = market.getMarketInfo(proposalId);
        assertEq(uint256(resolvedMarket.outcome), uint256(IMarket.Outcome.Yes), "Incorrect outcome");
        assertTrue(resolvedMarket.resolved, "Market not marked as resolved");
        assertEq(resolvedMarket.resolutionTime, block.timestamp, "Incorrect resolution time");
    }

    function test_ResolvingWithDifferentOutcomes() external {
        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(address(oracle));

        market.resolveMarket(proposalId, IMarket.Outcome.No);

        IMarket.MarketInfo memory resolvedMarket = market.getMarketInfo(proposalId);
        assertEq(uint256(resolvedMarket.outcome), uint256(IMarket.Outcome.No), "Incorrect outcome");

        // Create and resolve another market with Unresolved outcome
        bytes32 proposalId2 = keccak256("testProposal2");
        bytes32 questionHash = keccak256("some ipfs hash to a question");

        vm.prank(address(dao));
        market.createMarket(proposalId2, questionHash, tradingPeriod);

        vm.warp(block.timestamp + tradingPeriod + 1);
        vm.prank(address(oracle));
        market.resolveMarket(proposalId2, IMarket.Outcome.Unresolved);

        IMarket.MarketInfo memory resolvedMarket2 = market.getMarketInfo(proposalId2);
        assertEq(uint256(resolvedMarket2.outcome), uint256(IMarket.Outcome.Unresolved), "Incorrect outcome");
    }

    function test_ResolvingImmediatelyAfterTradingPeriod() external {
        vm.warp(block.timestamp + tradingPeriod);
        vm.prank(address(oracle));
        vm.expectRevert("Trading period has not ended");
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        vm.warp(block.timestamp + 1);
        vm.prank(address(oracle));
        market.resolveMarket(proposalId, IMarket.Outcome.Yes);

        IMarket.MarketInfo memory resolvedMarket = market.getMarketInfo(proposalId);
        assertTrue(resolvedMarket.resolved, "Market not marked as resolved");
    }
}

contract ClaimWinningsTest is FutarchyMarketTestBase {
    bytes32 proposalId;
    uint256 tradingPeriod;
    uint256 constant BUY_AMOUNT = 100 * 10 ** 18;

    function setUp() public override {
        super.setUp();
        proposalId = keccak256("testProposal");
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, questionHash, tradingPeriod);
        // Buy some shares for testing
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT);
        vm.prank(bob);
        market.buyShares(proposalId, false, BUY_AMOUNT);
    }

    function test_RevertWhen_MarketDoesntExist() external {
        bytes32 nonExistentProposalId = keccak256("nonExistentProposal");
        vm.prank(alice);
        vm.expectRevert("Market does not exist");
        market.claimWinnings(nonExistentProposalId);
    }

    function test_RevertWhen_MarketIsNotResolved() external {
        vm.prank(alice);
        vm.expectRevert("Market is not resolved");
        market.claimWinnings(proposalId);
    }

    function test_RevertWhen_UserHasNoWinningShares() external {
        // Resolve market with YES outcome
        vm.warp(block.timestamp + tradingPeriod + 1);
        oracle.resolveMarket(address(market), proposalId, IMarket.Outcome.Yes);

        // Bob tries to claim winnings but has no YES shares
        vm.prank(bob);
        vm.expectRevert("No winning shares to claim");
        market.claimWinnings(proposalId);
    }

    function test_WhenAllConditionsAreMet() external {
        // Resolve market with YES outcome
        vm.warp(block.timestamp + tradingPeriod + 1);
        oracle.resolveMarket(address(market), proposalId, IMarket.Outcome.Yes);

        uint256 aliceBalanceBefore = governanceToken.balanceOf(alice);
        uint256 expectedWinnings = market.calculateWinnings(proposalId, alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IMarket.WinningsClaimed(proposalId, alice, expectedWinnings);
        market.claimWinnings(proposalId);

        uint256 aliceBalanceAfter = governanceToken.balanceOf(alice);
        assertEq(aliceBalanceAfter, aliceBalanceBefore + expectedWinnings, "Incorrect winnings amount");

        // Check that Alice's position is reset
        IMarket.Position memory alicePositionAfter = market.getPosition(proposalId, alice);
        assertEq(alicePositionAfter.yesShares, 0, "YES shares not reset");
        assertEq(alicePositionAfter.noShares, 0, "NO shares not reset");

        // Ensure Alice can't claim again
        vm.expectRevert("No winning shares to claim");
        market.claimWinnings(proposalId);
    }

    function test_ClaimWinningsWithDifferentOutcomes() external {
        // Buy more shares to create an imbalance
        vm.prank(charlie);
        market.buyShares(proposalId, true, BUY_AMOUNT * 2);

        // Resolve market with NO outcome
        vm.warp(block.timestamp + tradingPeriod + 1);
        oracle.resolveMarket(address(market), proposalId, IMarket.Outcome.No);

        uint256 bobBalanceBefore = governanceToken.balanceOf(bob);
        uint256 expectedWinnings = market.calculateWinnings(proposalId, bob);

        vm.prank(bob);
        market.claimWinnings(proposalId);

        uint256 bobBalanceAfter = governanceToken.balanceOf(bob);
        assertEq(bobBalanceAfter, bobBalanceBefore + expectedWinnings, "Incorrect winnings amount for Bob");

        // Ensure Charlie can't claim (bought YES shares)
        vm.prank(charlie);
        vm.expectRevert("No winning shares to claim");
        market.claimWinnings(proposalId);
    }
}

contract GetPositionTest is FutarchyMarketTestBase {
    bytes32 proposalId;
    uint256 tradingPeriod;
    uint256 constant BUY_AMOUNT = 100 * 10 ** 18;

    function setUp() public override {
        super.setUp();
        proposalId = keccak256("testProposal");
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, questionHash, tradingPeriod);
    }

    function test_RevertWhen_MarketDoesntExist() external {
        bytes32 nonExistentProposalId = keccak256("nonExistentProposal");
        vm.expectRevert("Market does not exist");
        market.getPosition(nonExistentProposalId, alice);
    }

    function test_WhenMarketExists() external {
        // Buy YES shares
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT);

        // Buy NO shares
        vm.prank(bob);
        market.buyShares(proposalId, false, BUY_AMOUNT);

        // Check Alice's position
        IMarket.Position memory alicePosition = market.getPosition(proposalId, alice);
        assertGt(alicePosition.yesShares, 0, "Alice should have YES shares");
        assertEq(alicePosition.noShares, 0, "Alice should have no NO shares");

        // Check Bob's position
        IMarket.Position memory bobPosition = market.getPosition(proposalId, bob);
        assertEq(bobPosition.yesShares, 0, "Bob should have no YES shares");
        assertGt(bobPosition.noShares, 0, "Bob should have NO shares");

        // Check Charlie's position (who hasn't bought any shares)
        IMarket.Position memory charliePosition = market.getPosition(proposalId, charlie);
        assertEq(charliePosition.yesShares, 0, "Charlie should have no YES shares");
        assertEq(charliePosition.noShares, 0, "Charlie should have no NO shares");
    }

    function test_PositionAfterMultipleTrades() external {
        // Alice buys YES shares
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT);

        // Alice buys more YES shares
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT / 2);

        // Alice buys some NO shares
        vm.prank(alice);
        market.buyShares(proposalId, false, BUY_AMOUNT / 4);

        IMarket.Position memory alicePosition = market.getPosition(proposalId, alice);
        assertGt(alicePosition.yesShares, 0, "Alice should have YES shares");
        assertGt(alicePosition.noShares, 0, "Alice should have NO shares");
        assertGt(alicePosition.yesShares, alicePosition.noShares, "Alice should have more YES shares than NO shares");
    }

    function test_PositionAfterSellingShares() external {
        // Alice buys YES shares
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT);

        IMarket.Position memory positionBeforeSelling = market.getPosition(proposalId, alice);

        // Alice sells half of her YES shares
        uint256 sharesToSell = positionBeforeSelling.yesShares / 2;
        vm.prank(alice);
        market.sellShares(proposalId, true, sharesToSell);

        IMarket.Position memory positionAfterSelling = market.getPosition(proposalId, alice);
        assertEq(
            positionAfterSelling.yesShares,
            positionBeforeSelling.yesShares - sharesToSell,
            "Alice's YES shares should decrease after selling"
        );
        assertEq(positionAfterSelling.noShares, 0, "Alice's NO shares should remain zero");
    }

    function test_PositionInMultipleMarkets() external {
        // Create a second market
        bytes32 proposalId2 = keccak256("testProposal2");
        bytes32 questionHash = keccak256("some ipfs hash to a question");
        vm.prank(address(dao));
        market.createMarket(proposalId2, questionHash, tradingPeriod);

        // Alice buys YES shares in first market
        vm.prank(alice);
        market.buyShares(proposalId, true, BUY_AMOUNT);

        // Alice buys NO shares in second market
        vm.prank(alice);
        market.buyShares(proposalId2, false, BUY_AMOUNT);

        IMarket.Position memory alicePosition1 = market.getPosition(proposalId, alice);
        IMarket.Position memory alicePosition2 = market.getPosition(proposalId2, alice);

        assertGt(alicePosition1.yesShares, 0, "Alice should have YES shares in first market");
        assertEq(alicePosition1.noShares, 0, "Alice should have no NO shares in first market");

        assertEq(alicePosition2.yesShares, 0, "Alice should have no YES shares in second market");
        assertGt(alicePosition2.noShares, 0, "Alice should have NO shares in second market");
    }
}
