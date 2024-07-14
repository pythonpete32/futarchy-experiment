// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarket {
    enum Outcome {
        Unresolved,
        Yes,
        No
    }

    struct MarketInfo {
        bytes32 proposalId;
        uint256 creationTime;
        uint256 resolutionTime;
        uint256 tradingPeriod;
        bool resolved;
        Outcome outcome;
        uint256 virtualReserve;
        uint256 actualYesShares;
        uint256 actualNoShares;
        uint256 totalFeesCollected;
    }

    struct Position {
        uint256 yesShares;
        uint256 noShares;
    }

    event MarketCreated(
        bytes32 indexed proposalId,
        uint256 virtualReserve,
        uint256 tradingPeriod
    );
    event SharesBought(
        bytes32 indexed proposalId,
        address indexed trader,
        bool isYes,
        uint256 shareAmount,
        uint256 tokenAmount
    );
    event SharesSold(
        bytes32 indexed proposalId,
        address indexed trader,
        bool isYes,
        uint256 shareAmount,
        uint256 tokenAmount
    );
    event MarketResolved(bytes32 indexed proposalId, Outcome outcome);

    function createMarket(
        bytes32 proposalId,
        uint256 virtualReserve,
        uint256 tradingPeriod
    ) external;

    function buyShares(bytes32 proposalId, bool isYes, uint256 amount) external;

    function sellShares(
        bytes32 proposalId,
        bool isYes,
        uint256 shareAmount
    ) external;

    function resolveMarket(bytes32 proposalId, Outcome outcome) external;

    function claimWinnings(bytes32 proposalId) external;

    function getYesPrice(bytes32 proposalId) external view returns (uint256);

    function getPosition(
        bytes32 proposalId,
        address trader
    ) external view returns (Position memory);

    function getMarketInfo(
        bytes32 proposalId
    ) external view returns (MarketInfo memory);
}

contract Market is IMarket {
    IERC20 public immutable governanceToken;
    address public immutable daoAddress;
    address public oracle;

    mapping(bytes32 => MarketInfo) public markets;
    mapping(bytes32 => mapping(address => Position)) public positions;

    constructor(
        address _governanceToken,
        address _daoAddress,
        address _oracle
    ) {
        governanceToken = IERC20(_governanceToken);
        daoAddress = _daoAddress;
        oracle = _oracle;
    }

    function createMarket(
        bytes32 proposalId,
        uint256 virtualReserve,
        uint256 tradingPeriod
    ) external override {
        require(msg.sender == daoAddress, "Only DAO can create markets");
        require(markets[proposalId].creationTime == 0, "Market already exists");

        markets[proposalId] = MarketInfo({
            proposalId: proposalId,
            creationTime: block.timestamp,
            resolutionTime: 0,
            tradingPeriod: tradingPeriod,
            resolved: false,
            outcome: Outcome.Unresolved,
            virtualReserve: virtualReserve,
            actualYesShares: 0,
            actualNoShares: 0,
            totalFeesCollected: 0
        });

        emit MarketCreated(proposalId, virtualReserve, tradingPeriod);
    }

    function buyShares(
        bytes32 proposalId,
        bool isYes,
        uint256 amount
    ) external override {
        MarketInfo storage market = markets[proposalId];
        require(
            block.timestamp < market.creationTime + market.tradingPeriod,
            "Trading period has ended"
        );
        require(!market.resolved, "Market already resolved");

        uint256 sharesBought = calculateSharesBought(
            market.virtualReserve,
            amount
        );
        require(
            governanceToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (isYes) {
            positions[proposalId][msg.sender].yesShares += sharesBought;
            market.actualYesShares += sharesBought;
        } else {
            positions[proposalId][msg.sender].noShares += sharesBought;
            market.actualNoShares += sharesBought;
        }

        emit SharesBought(proposalId, msg.sender, isYes, sharesBought, amount);
    }

    function sellShares(
        bytes32 proposalId,
        bool isYes,
        uint256 shareAmount
    ) external override {
        MarketInfo storage market = markets[proposalId];
        require(
            block.timestamp < market.creationTime + market.tradingPeriod,
            "Trading period has ended"
        );
        require(!market.resolved, "Market already resolved");

        Position storage position = positions[proposalId][msg.sender];
        require(
            isYes
                ? position.yesShares >= shareAmount
                : position.noShares >= shareAmount,
            "Insufficient shares"
        );

        uint256 tokenAmount = calculateTokensReceived(
            market.virtualReserve,
            shareAmount
        );

        if (isYes) {
            position.yesShares -= shareAmount;
            market.actualYesShares -= shareAmount;
        } else {
            position.noShares -= shareAmount;
            market.actualNoShares -= shareAmount;
        }

        require(
            governanceToken.transfer(msg.sender, tokenAmount),
            "Transfer failed"
        );

        emit SharesSold(
            proposalId,
            msg.sender,
            isYes,
            shareAmount,
            tokenAmount
        );
    }

    function resolveMarket(
        bytes32 proposalId,
        Outcome outcome
    ) external override {
        require(msg.sender == oracle, "Only oracle can resolve markets");
        MarketInfo storage market = markets[proposalId];
        require(!market.resolved, "Market already resolved");
        require(
            block.timestamp >= market.creationTime + market.tradingPeriod,
            "Trading period not over"
        );

        market.resolved = true;
        market.outcome = outcome;
        market.resolutionTime = block.timestamp;

        emit MarketResolved(proposalId, outcome);
    }

    function claimWinnings(bytes32 proposalId) external override {
        MarketInfo storage market = markets[proposalId];
        require(market.resolved, "Market not resolved");

        Position storage position = positions[proposalId][msg.sender];
        uint256 winningShares = market.outcome == Outcome.Yes
            ? position.yesShares
            : position.noShares;

        require(winningShares > 0, "No winning shares");

        uint256 totalShares = market.actualYesShares + market.actualNoShares;
        uint256 payout = (winningShares * market.virtualReserve) / totalShares;

        if (market.outcome == Outcome.Yes) {
            position.yesShares = 0;
        } else {
            position.noShares = 0;
        }

        require(
            governanceToken.transfer(msg.sender, payout),
            "Transfer failed"
        );
    }

    function getYesPrice(
        bytes32 proposalId
    ) external view override returns (uint256) {
        MarketInfo storage market = markets[proposalId];
        uint256 totalShares = market.actualYesShares + market.actualNoShares;
        if (totalShares == 0) return 500000; // 50% in fixed point with 6 decimals
        return (market.actualYesShares * 1000000) / totalShares; // Price in fixed point with 6 decimals
    }

    function getPosition(
        bytes32 proposalId,
        address trader
    ) external view override returns (Position memory) {
        return positions[proposalId][trader];
    }

    function getMarketInfo(
        bytes32 proposalId
    ) external view override returns (MarketInfo memory) {
        return markets[proposalId];
    }

    // Helper functions for share and token calculations
    function calculateSharesBought(
        uint256 virtualReserve,
        uint256 tokenAmount
    ) internal pure returns (uint256) {
        return (tokenAmount * virtualReserve) / (virtualReserve + tokenAmount);
    }

    function calculateTokensReceived(
        uint256 virtualReserve,
        uint256 shareAmount
    ) internal pure returns (uint256) {
        return (shareAmount * virtualReserve) / (virtualReserve - shareAmount);
    }
}
