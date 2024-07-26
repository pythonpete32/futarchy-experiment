// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IDAO, DAO} from "../src/mocks/MockDAO.sol";
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

        market = new FutarchyMarket(
            address(governanceToken),
            address(dao),
            address(oracle)
        );

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
        uint256 tradingPeriod = 7 days;

        vm.prank(alice);
        vm.expectRevert("Caller is not the DAO");
        market.createMarket(proposalId, tradingPeriod);
    }

    function test_RevertWhen_MarketAlreadyExists() external {
        bytes32 proposalId = keccak256("proposal1");
        uint256 tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, tradingPeriod);

        vm.prank(address(dao));
        vm.expectRevert("Market already exists");
        market.createMarket(proposalId, tradingPeriod);
    }

    function test_WhenCallerIsDAOAndMarketDoesntExist() external {
        bytes32 proposalId = keccak256(abi.encode(block.timestamp));
        uint256 tradingPeriod = 7 days;

        vm.prank(address(dao));
        vm.expectEmit(true, true, true, true);
        emit IMarket.MarketCreated(proposalId, tradingPeriod);
        market.createMarket(proposalId, tradingPeriod);

        IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
        assertEq(
            marketInfo.proposalId,
            proposalId,
            "ProposalID not saved correctly"
        );
        assertEq(marketInfo.tradingPeriod, tradingPeriod);
        assertEq(marketInfo.creationTime, block.timestamp);
        assertEq(marketInfo.resolved, false);
        assertEq(uint(marketInfo.outcome), uint(IMarket.Outcome.Unresolved));
        assertEq(marketInfo.yesShares, 0);
        assertEq(marketInfo.noShares, 0);
        assertEq(
            marketInfo.yesReserve,
            FutarchyMarket(market).INITIAL_LIQUIDITY()
        );
        assertEq(
            marketInfo.noReserve,
            FutarchyMarket(market).INITIAL_LIQUIDITY()
        );
    }
}

contract BuySharesTest is FutarchyMarketTestBase {
    bytes32 proposalId;
    uint256 tradingPeriod;

    function setUp() public override {
        super.setUp();
        proposalId = keccak256("testProposal");
        tradingPeriod = 7 days;

        vm.prank(address(dao));
        market.createMarket(proposalId, tradingPeriod);
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
                IERC20Errors.ERC20InsufficientBalance.selector,
                alice,
                1000 * 10 ** 18,
                excessiveAmount
            )
        );
        market.buyShares(proposalId, true, excessiveAmount);
    }

    function test_WhenAllConditionsAreMet() external {
        uint256 buyAmount = 10 * 10 ** 18;
        (uint256 sharesToMint, ) = market.getSharesOutAmount(
            proposalId,
            true,
            buyAmount
        );
        uint256 aliceBalanceBefore = governanceToken.balanceOf(alice);
        uint256 marketBalanceBefore = governanceToken.balanceOf(
            address(market)
        );
        IMarket.MarketInfo memory marketInfoBefore = market.getMarketInfo(
            proposalId
        );
        uint256 sharesBefore = marketInfoBefore.yesShares;

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);

        emit IMarket.SharesBought(
            proposalId,
            alice,
            true,
            sharesToMint,
            buyAmount
        );
        market.buyShares(proposalId, true, buyAmount);

        // Check token transfer
        assertEq(
            governanceToken.balanceOf(alice),
            aliceBalanceBefore - buyAmount,
            "Incorrect token transfer from user"
        );
        assertEq(
            governanceToken.balanceOf(address(market)),
            marketBalanceBefore + buyAmount,
            "Incorrect token transfer to market"
        );

        // Check share minting and market update
        IMarket.Position memory alicePosition = market.getPosition(
            proposalId,
            alice
        );
        assertGt(alicePosition.yesShares, 0, "Shares not minted to user");

        IMarket.MarketInfo memory marketInfo = market.getMarketInfo(proposalId);
        assertEq(
            marketInfo.yesShares - sharesBefore,
            alicePosition.yesShares,
            "Market shares not updated correctly"
        );
        assertEq(
            marketInfo.yesReserve,
            FutarchyMarket(market).INITIAL_LIQUIDITY() + buyAmount,
            "Market reserve not updated correctly"
        );
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

contract GetPriceTest is FutarchyMarketTestBase {
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
