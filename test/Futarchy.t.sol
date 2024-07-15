// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IDAO, DAO} from "../src/mocks/MockDAO.sol";
import {IMarket, FutarchyMarket} from "../src/FutarchyMarket.sol";
import {Oracle} from "../src/mocks/MockOracle.sol";
import {MockGovernanceToken} from "../src/mocks/MockGovernanceToken.sol";

abstract contract FutarchyMarketTestBase is Test {
    FutarchyMarket market;
    MockGovernanceToken governanceToken;
    DAO dao;
    address oracle;

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public virtual {
        governanceToken = new MockGovernanceToken();
        dao = new DAO();
        oracle = address(0x4);
        market = new FutarchyMarket(
            address(governanceToken),
            address(dao),
            oracle
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
}

contract CreateMarketTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
    }

    function test_RevertWhen_CallerIsNotDAO() external {
        // It should revert with an unauthorized error.
    }

    function test_RevertWhen_MarketAlreadyExists() external {
        // It should revert with a market already exists error.
    }

    function test_WhenCallerIsDAOAndMarketDoesntExist() external {
        // It should create a new market with the given parameters.
        // It should emit a MarketCreated event.
    }
}

contract BuySharesTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
        // Additional setup for buy shares tests
    }

    function test_RevertWhen_MarketDoesntExist() external {
        // It should revert with a market not found error.
    }

    function test_RevertWhen_TradingPeriodHasEnded() external {
        // It should revert with a trading period ended error.
    }

    function test_RevertWhen_MarketIsAlreadyResolved() external {
        // It should revert with a market already resolved error.
    }

    function test_RevertWhen_UserDoesntHaveEnoughTokens() external {
        // It should revert with an insufficient balance error.
    }

    function test_WhenAllConditionsAreMet() external {
        // It should process the share purchase correctly.
        // It should transfer tokens from the user to the contract.
        // It should mint the correct amount of shares to the user.
        // It should update the market's share counts.
        // It should emit a SharesBought event.
    }
}

contract SellSharesTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
        // Additional setup for sell shares tests
    }

    function test_RevertWhen_MarketDoesntExist() external {
        // It should revert with a market not found error.
    }

    function test_RevertWhen_TradingPeriodHasEnded() external {
        // It should revert with a trading period ended error.
    }

    function test_RevertWhen_MarketIsAlreadyResolved() external {
        // It should revert with a market already resolved error.
    }

    function test_RevertWhen_UserDoesntHaveEnoughShares() external {
        // It should revert with an insufficient shares error.
    }

    function test_WhenAllConditionsAreMet() external {
        // It should process the share sale correctly.
        // It should burn the shares from the user.
        // It should transfer tokens to the user.
        // It should update the market's share counts.
        // It should emit a SharesSold event.
    }
}

contract ResolveMarketTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
        // Additional setup for resolve market tests
    }

    function test_RevertWhen_CallerIsNotOracle() external {
        // It should revert with an unauthorized error.
    }

    function test_RevertWhen_MarketDoesntExist() external {
        // It should revert with a market not found error.
    }

    function test_RevertWhen_MarketIsAlreadyResolved() external {
        // It should revert with a market already resolved error.
    }

    function test_RevertWhen_TradingPeriodHasntEnded() external {
        // It should revert with a trading period not ended error.
    }

    function test_WhenAllConditionsAreMet() external {
        // It should resolve the market correctly.
        // It should set the market as resolved.
        // It should set the outcome.
        // It should emit a MarketResolved event.
    }
}

contract ClaimWinningsTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
        // Additional setup for claim winnings tests
    }

    function test_RevertWhen_MarketDoesntExist() external {
        // It should revert with a market not found error.
    }

    function test_RevertWhen_MarketIsNotResolved() external {
        // It should revert with a market not resolved error.
    }

    function test_RevertWhen_UserHasNoWinningShares() external {
        // It should revert with a no winning shares error.
    }

    function test_WhenAllConditionsAreMet() external {
        // It should process the winning claim correctly.
        // It should calculate the correct payout.
        // It should transfer tokens to the user.
        // It should reset the user's position.
        // It should emit a WinningsClaimed event.
    }
}

contract GetYesPriceTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
        // Additional setup for get yes price tests
    }

    function test_RevertWhen_MarketDoesntExist() external {
        // It should revert with a market not found error.
    }

    function test_WhenNoSharesHaveBeenBought() external {
        // It should return 500000 (50%).
    }

    function test_WhenSharesHaveBeenBought() external {
        // It should return the correct price based on the share ratio.
    }
}

contract GetPositionTest is FutarchyMarketTestBase {
    function setUp() public override {
        super.setUp();
        // Additional setup for get position tests
    }

    function test_RevertWhen_MarketDoesntExist() external {
        // It should revert with a market not found error.
    }

    function test_WhenMarketExists() external {
        // It should return the correct position for the given user.
    }
}

// contract FutarchyTest is Test {
//     IDAO dao;
//     IMarket market;
//     MockGovernanceToken governanceToken;
//     address oracle = address(0x04ac1e);

//     address alice = address(0x1);
//     address bob = address(0x2);
//     address charlie = address(0x3);

//     function setUp() public {
//         governanceToken = new MockGovernanceToken();
//         dao = new DAO();
//         oracle = address(0x2);
//         market = new FutarchyMarket(
//             address(governanceToken),
//             address(dao),
//             address(oracle)
//         );

//         governanceToken.mint(alice, 1000000 * 10 ** 18);
//         governanceToken.mint(bob, 1000000 * 10 ** 18);
//         governanceToken.mint(charlie, 1000000 * 10 ** 18);

//         vm.prank(alice);
//         governanceToken.approve(address(market), type(uint256).max);
//         vm.prank(bob);
//         governanceToken.approve(address(market), type(uint256).max);
//         vm.prank(charlie);
//         governanceToken.approve(address(market), type(uint256).max);
//     }

//     function testCreateProposal() public {
//         vm.prank(alice);
//         bytes32 proposalId = dao.createProposal("Test Proposal", 1 days);
//         IDAO.Proposal memory proposal = dao.getProposal(proposalId);
//         assertEq(proposal.proposer, alice);
//         assertEq(proposal.description, "Test Proposal");
//         assertEq(proposal.votingEndTime, block.timestamp + 1 days);
//     }

//     function testCreateMarket() public {
//         bytes32 proposalId = _createProposal();

//         vm.prank(address(dao));
//         market.createMarket(proposalId, 1000 * 10 ** 18, 2 days);

//         IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
//         assertEq(marketInfo.proposalId, proposalId);
//         assertEq(marketInfo.tradingPeriod, 2 days);
//         assertEq(marketInfo.virtualReserve, 1000 * 10 ** 18);
//         assertEq(marketInfo.resolved, false);
//     }

//     function testBuyShares() public {
//         bytes32 proposalId = _createProposalAndMarket();

//         vm.prank(bob);
//         market.buyShares(proposalId, true, 100 * 10 ** 18);

//         IMarket.Position memory position = market.getPosition(proposalId, bob);
//         assertGt(position.yesShares, 0);
//         assertEq(position.noShares, 0);

//         uint256 yesPrice = market.getYesPrice(proposalId);
//         assertGt(yesPrice, 500000); // Price should be higher than 50%
//     }

//     function testSellShares() public {
//         bytes32 proposalId = _createProposalAndMarket();

//         vm.startPrank(bob);
//         market.buyShares(proposalId, true, 100 * 10 ** 18);
//         uint256 initialYesShares = market
//             .getPosition(proposalId, bob)
//             .yesShares;
//         market.sellShares(proposalId, true, initialYesShares / 2);
//         vm.stopPrank();

//         IMarket.Position memory position = market.getPosition(proposalId, bob);
//         assertEq(position.yesShares, initialYesShares / 2);
//     }

//     function testMarketResolution() public {
//         bytes32 proposalId = _createProposalAndMarket();

//         vm.warp(block.timestamp + 2 days);

//         vm.prank(address(oracle));
//         market.resolveMarket(proposalId, IMarket.Outcome.Yes);

//         IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
//         assertTrue(marketInfo.resolved);
//         assertEq(uint(marketInfo.outcome), uint(IMarket.Outcome.Yes));
//     }

//     function testClaimWinnings() public {
//         bytes32 proposalId = _createProposalAndMarket();

//         vm.prank(bob);
//         market.buyShares(proposalId, true, 100 * 10 ** 18);

//         vm.prank(charlie);
//         market.buyShares(proposalId, false, 100 * 10 ** 18);

//         vm.warp(block.timestamp + 2 days);

//         vm.prank(address(oracle));
//         market.resolveMarket(proposalId, IMarket.Outcome.Yes);

//         uint256 bobBalanceBefore = governanceToken.balanceOf(bob);

//         vm.prank(bob);
//         market.claimWinnings(proposalId);

//         uint256 bobBalanceAfter = governanceToken.balanceOf(bob);
//         assertGt(bobBalanceAfter, bobBalanceBefore);
//     }

//     function testGetYesPrice() public {
//         bytes32 proposalId = _createProposalAndMarket();

//         uint256 initialPrice = market.getYesPrice(proposalId);
//         assertEq(initialPrice, 500000); // 50% initial price

//         vm.prank(bob);
//         market.buyShares(proposalId, true, 100 * 10 ** 18);

//         uint256 newPrice = market.getYesPrice(proposalId);
//         assertGt(newPrice, initialPrice);
//     }

//     function _createProposal() internal returns (bytes32) {
//         vm.prank(alice);
//         return dao.createProposal("Test Proposal", 1 days);
//     }

//     function _createProposalAndMarket() internal returns (bytes32) {
//         bytes32 proposalId = _createProposal();
//         vm.prank(address(dao));
//         market.createMarket(proposalId, 1000 * 10 ** 18, 2 days);
//         return proposalId;
//     }
// }
