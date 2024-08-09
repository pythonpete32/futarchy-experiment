// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMarket} from "./interfaces/IMarket.sol";

/// @title Futarchy Market Contract
/// @notice This contract implements a futarchy-based prediction market for DAO proposals
/// @dev This contract uses virtual liquidity and a simplified CPMM model
contract FutarchyMarket is IMarket {
    /// @notice The governance token used for trading in the market
    IERC20 public immutable governanceToken;

    /// @notice Initial liquidity requirement of governance tokens in both YES and NO markets
    /// @dev This is added by the DAO when creating a market to smooth out initial price volatility
    uint256 public constant INITIAL_LIQUIDITY = 1000 * 10 ** 18;

    /// @notice Precision factor for price calculations. The price is represented as a fixed-point number with x decimal places.
    uint256 public constant PRICE_PRECISION = 1e18;

    /// @notice The address of the DAO contract
    address public immutable daoAddress;

    /// @notice The address authorized to resolve markets
    address public oracle;

    /// @notice Mapping from proposalId to MarketInfo
    mapping(bytes32 => MarketInfo) public markets;

    /// @notice Mapping from proposalId to user address to their position
    mapping(bytes32 => mapping(address => Position)) public positions;

    /// @notice Constructs the FutarchyMarket contract
    /// @param _governanceToken The address of the governance token contract
    /// @param _daoAddress The address of the DAO contract
    /// @param _oracle The address authorized to resolve markets
    constructor(address _governanceToken, address _daoAddress, address _oracle) {
        governanceToken = IERC20(_governanceToken);
        daoAddress = _daoAddress;
        oracle = _oracle;
    }

    /// @notice Creates a new market for a proposal
    /// @param proposalId The ID of the proposal for which to create a market
    /// @param questionHash The hash of the question associated with the proposal
    /// @param tradingPeriod The duration of the trading period
    /// @dev Only the DAO contract can call this function
    function createMarket(bytes32 proposalId, bytes32 questionHash, uint256 tradingPeriod) external {
        // 1. Verify that the caller is the DAO contract (msg.sender == daoAddress)
        require(msg.sender == daoAddress, "Caller is not the DAO");

        // 2. Ensure the market doesn't already exist (markets[proposalId].creationTime == 0)
        require(markets[proposalId].creationTime == 0, "Market already exists");

        // 3. Transfer INITIAL_LIQUIDITY * 2 tokens from the DAO to this contract
        require(
            governanceToken.transferFrom(daoAddress, address(this), INITIAL_LIQUIDITY * 2),
            "Failed to transfer initial liquidity"
        );

        // 4. Create a new MarketInfo struct:
        MarketInfo memory newMarket = MarketInfo({
            proposalId: proposalId,
            questionHash: questionHash,
            creationTime: block.timestamp,
            tradingPeriod: tradingPeriod,
            resolved: false,
            outcome: Outcome.Unresolved,
            yesShares: INITIAL_LIQUIDITY,
            noShares: INITIAL_LIQUIDITY,
            yesReserve: INITIAL_LIQUIDITY,
            noReserve: INITIAL_LIQUIDITY,
            resolutionTime: 0
        });

        // 5. Store the new MarketInfo in markets[proposalId]
        markets[proposalId] = newMarket;

        // 6. Mint initial shares to the DAO
        positions[proposalId][daoAddress].yesShares += INITIAL_LIQUIDITY;
        positions[proposalId][daoAddress].noShares += INITIAL_LIQUIDITY;

        // 6. Emit MarketCreated event
        emit MarketCreated(proposalId, tradingPeriod);
    }

    /// @notice Allows a user to buy shares in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param amount The amount of governance tokens to spend
    function buyShares(bytes32 proposalId, bool position, uint256 amount) external {
        // 1. Retrieve market info for proposalId
        MarketInfo storage market = markets[proposalId];

        // 2. Ensure the market exists and is within the trading period
        require(!market.resolved, "Market is already resolved");
        require(market.creationTime != 0, "Market does not exist");
        require(block.timestamp <= market.creationTime + market.tradingPeriod, "Trading period has ended");

        // 6. Transfer inputAmount of governanceTokens from user to contract
        require(governanceToken.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");

        (uint256 sharesToMint,) = getSharesOutAmount(proposalId, position, amount);

        require(sharesToMint > 0, "Insufficient shares to mint");

        // 5. Update market state:
        if (position) {
            market.yesReserve += amount;
            market.yesShares += sharesToMint;

            positions[proposalId][msg.sender].yesShares += sharesToMint;
        } else {
            market.noReserve += amount;
            market.noShares += sharesToMint;
            // If position is NO: positions[proposalId][msg.sender].noShares += shares
            positions[proposalId][msg.sender].noShares += sharesToMint;
        }

        // 8. Emit SharesBought event
        emit SharesBought(proposalId, msg.sender, position, sharesToMint, amount);
    }

    /// @notice Allows a user to sell shares in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param shareAmount The number of shares to sell
    function sellShares(bytes32 proposalId, bool position, uint256 shareAmount) external {
        // 1. Retrieve market info for proposalId
        MarketInfo storage market = markets[proposalId];

        // 2. Ensure the market exists and is within the trading period
        // 3. Ensure user has enough shares to sell
        require(market.creationTime != 0, "Market does not exist");
        require(!market.resolved, "Market is already resolved");
        require(block.timestamp <= market.creationTime + market.tradingPeriod, "Trading period has ended");

        // 4. Determine input_reserve and output_reserve based on position:
        Position storage userPosition = positions[proposalId][msg.sender];
        if (position) {
            require(userPosition.yesShares >= shareAmount, "Insufficient YES shares");
        } else {
            require(userPosition.noShares >= shareAmount, "Insufficient NO shares");
        }

        // 5. Calculate tokens to return:
        (uint256 tokensToReceive,) = getTokensOutAmount(proposalId, position, shareAmount);

        // 6. Update market state:
        if (position) {
            market.yesReserve -= tokensToReceive;
            market.yesShares -= shareAmount;
            userPosition.yesShares -= shareAmount;
        } else {
            market.noReserve -= tokensToReceive;
            market.noShares -= shareAmount;
            userPosition.noShares -= shareAmount;
        }
        // 8. Transfer tokens of governanceTokens to user
        require(governanceToken.transfer(msg.sender, tokensToReceive), "Failed to transfer tokens");

        // 9. Emit SharesSold event
        emit SharesSold(proposalId, msg.sender, position, shareAmount, tokensToReceive);
    }

    /// @notice Calculates the amount of shares that would be received for a given input amount
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param amount The amount of governance tokens to spend
    /// @return sharesReceived The amount of shares that would be received
    /// @return effectivePrice The effective price per share, accounting for slippage
    function getSharesOutAmount(bytes32 proposalId, bool position, uint256 amount)
        public
        view
        returns (uint256 sharesReceived, uint256 effectivePrice)
    {
        MarketInfo storage market = markets[proposalId];
        require(market.creationTime != 0, "Market does not exist");

        uint256 inputReserve = position ? market.yesReserve : market.noReserve;
        uint256 outputShares = position ? market.yesShares : market.noShares;

        sharesReceived = (amount * outputShares) / (inputReserve + amount);

        // Calculate effective price, considering PRICE_PRECISION
        effectivePrice = (amount * PRICE_PRECISION) / sharesReceived;

        return (sharesReceived, effectivePrice);
    }

    /// @notice Calculates the amount of tokens that would be received for selling a given amount of shares
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param shareAmount The number of shares to sell
    /// @return tokensToReceive The amount of tokens that would be received
    /// @return effectivePrice The effective price per share, accounting for slippage
    function getTokensOutAmount(bytes32 proposalId, bool position, uint256 shareAmount)
        public
        view
        returns (uint256 tokensToReceive, uint256 effectivePrice)
    {
        MarketInfo storage market = markets[proposalId];
        require(market.creationTime != 0, "Market does not exist");
        uint256 inputShares = position ? market.yesShares : market.noShares;
        uint256 outputReserve = position ? market.yesReserve : market.noReserve;

        tokensToReceive = (shareAmount * outputReserve) / inputShares;
        effectivePrice = (tokensToReceive * PRICE_PRECISION) / shareAmount;

        return (tokensToReceive, effectivePrice);
    }

    /// @notice Resolves a market with the final outcome
    /// @param proposalId The ID of the proposal associated with the market
    /// @param outcome The final outcome of the market
    /// @dev Only the oracle can call this function
    function resolveMarket(bytes32 proposalId, Outcome outcome) external {
        // 1. Ensure caller is oracle
        require(msg.sender == oracle, "Caller is not the oracle");

        // 2. Retrieve market info for proposalId
        MarketInfo storage market = markets[proposalId];

        // 3. Ensure market exists and is not already resolved
        require(market.creationTime != 0, "Market does not exist");
        require(!market.resolved, "Market is already resolved");
        require(block.timestamp > market.creationTime + market.tradingPeriod, "Trading period has not ended");
        // 4. Update market:
        market.resolved = true;
        market.resolutionTime = block.timestamp;
        market.outcome = outcome;

        // 5. Emit MarketResolved event
        emit MarketResolved(proposalId, outcome);
    }

    /// @notice Allows a user to claim their winnings from a resolved market
    /// @param proposalId The ID of the proposal associated with the market
    function claimWinnings(bytes32 proposalId) external {
        // 1. Retrieve market info for proposalId
        MarketInfo storage market = markets[proposalId];

        uint256 winningShares;
        uint256 totalWinningShares;
        uint256 totalReserve = market.yesReserve + market.noReserve;

        // 2. Ensure market is resolved
        require(market.creationTime != 0, "Market does not exist");
        require(market.resolved, "Market is not resolved");

        // 3. Retrieve user's position
        Position storage userPosition = positions[proposalId][msg.sender];
        // 4. Calculate winnings based on outcome and user's position:
        //    - If outcome is Yes, winnings = user's yesShares * (totalReserve / totalYesShares)
        //    - If outcome is No, winnings = user's noShares * (totalReserve / totalNoShares)
        if (market.outcome == Outcome.Yes) {
            winningShares = userPosition.yesShares;
            totalWinningShares = market.yesShares;
        } else if (market.outcome == Outcome.No) {
            winningShares = userPosition.noShares;
            totalWinningShares = market.noShares;
        } else {
            revert("Market outcome is invalid");
        }
        require(winningShares > 0, "No winning shares to claim");
        uint256 winnings = (winningShares * totalReserve) / totalWinningShares;

        // 5. Clear user's position
        userPosition.yesShares = 0;
        userPosition.noShares = 0;

        // 6. Transfer winnings to user
        require(governanceToken.transfer(msg.sender, winnings), "Transfer failed");

        // Transfer winnings to user
        emit WinningsClaimed(proposalId, msg.sender, winnings);
    }

    /// @notice Calculates the winnings for a user in a given market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param user The address of the user
    /// @return winnings The amount of winnings the user can claim
    function calculateWinnings(bytes32 proposalId, address user) public view returns (uint256 winnings) {
        MarketInfo storage market = markets[proposalId];
        require(market.resolved, "Market is not resolved");

        Position storage userPosition = positions[proposalId][user];
        uint256 winningShares;
        uint256 totalWinningShares;
        uint256 totalReserve = market.yesReserve + market.noReserve;

        if (market.outcome == Outcome.Yes) {
            winningShares = userPosition.yesShares;
            totalWinningShares = market.yesShares;
        } else if (market.outcome == Outcome.No) {
            winningShares = userPosition.noShares;
            totalWinningShares = market.noShares;
        } else {
            return 0; // No winnings if the market outcome is invalid
        }

        if (winningShares == 0 || totalWinningShares == 0) {
            return 0;
        }

        winnings = (winningShares * totalReserve) / totalWinningShares;
        return winnings;
    }

    /// @notice Retrieves the current position of a user in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param user The address of the user
    /// @return The user's position (number of YES and NO shares)
    function getPosition(bytes32 proposalId, address user) external view returns (Position memory) {
        require(markets[proposalId].creationTime != 0, "Market does not exist");
        return positions[proposalId][user];
    }

    /// @notice Allows the DAO to update the oracle address
    /// @param newOracle The address of the new oracle
    /// @dev Only the DAO contract can call this function
    function updateOracle(address newOracle) external {
        require(msg.sender == daoAddress, "Caller is not the DAO");
        require(newOracle != address(0), "Invalid oracle address");
        oracle = newOracle;
        emit OracleUpdated(newOracle);
    }

    function getMarketInfo(bytes32 proposalId) external view override returns (MarketInfo memory) {
        require(markets[proposalId].creationTime != 0, "Market does not exist");
        return markets[proposalId];
    }
}
