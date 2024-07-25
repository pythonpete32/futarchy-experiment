// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
    constructor(
        address _governanceToken,
        address _daoAddress,
        address _oracle
    ) {
        governanceToken = IERC20(_governanceToken);
        daoAddress = _daoAddress;
        oracle = _oracle;
    }

    /// @notice Creates a new market for a proposal
    /// @param proposalId The ID of the proposal for which to create a market
    /// @param tradingPeriod The duration of the trading period
    /// @dev Only the DAO contract can call this function
    function createMarket(bytes32 proposalId, uint256 tradingPeriod) external {
        // TODO: Implement market creation logic
        // 1. Verify that the caller is the DAO contract (msg.sender == daoAddress)
        // 2. Ensure the market doesn't already exist (markets[proposalId].creationTime == 0)
        // 3. Create a new MarketInfo struct:
        //    - proposalId = proposalId
        //    - creationTime = current block timestamp
        //    - tradingPeriod = tradingPeriod
        //    - resolved = false
        //    - outcome = Outcome.Unresolved
        //    - yesShares = 0
        //    - noShares = 0
        //    - yesReserve = INITIAL_LIQUIDITY
        //    - noReserve = INITIAL_LIQUIDITY
        // 4. Store the new MarketInfo in markets[proposalId]
        // 5. Transfer INITIAL_LIQUIDITY * 2 tokens from the DAO to this contract
        // 6. Emit MarketCreated event
    }

    /// @notice Allows a user to buy shares in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param amount The amount of governance tokens to spend
    function buyShares(
        bytes32 proposalId,
        bool position,
        uint256 amount
    ) external {
        // TODO: Implement share buying logic
        // 1. Retrieve market info for proposalId
        // 2. Ensure the market exists and is within the trading period
        // 3. Determine input_reserve and output_reserve based on position:
        //    - If position is YES: input_reserve = yesReserve, output_reserve = yesShares
        //    - If position is NO: input_reserve = noReserve, output_reserve = noShares
        // 4. Calculate shares to mint:
        //    shares = (inputAmount * output_reserve) / (input_reserve + inputAmount)
        // 5. Update market state:
        //    - If position is YES:
        //      yesReserve += inputAmount
        //      yesShares += shares
        //    - If position is NO:
        //      noReserve += inputAmount
        //      noShares += shares
        // 6. Transfer inputAmount of governanceTokens from user to contract
        // 7. Update user's position in positions mapping:
        //    - If position is YES: positions[proposalId][msg.sender].yesShares += shares
        //    - If position is NO: positions[proposalId][msg.sender].noShares += shares
        // 8. Emit SharesBought event
    }

    /// @notice Allows a user to sell shares in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @param shareAmount The number of shares to sell
    function sellShares(
        bytes32 proposalId,
        bool position,
        uint256 shareAmount
    ) external {
        // TODO: Implement share selling logic
        // 1. Retrieve market info for proposalId
        // 2. Ensure the market exists and is within the trading period
        // 3. Ensure user has enough shares to sell
        // 4. Determine input_reserve and output_reserve based on position:
        //    - If position is YES: input_reserve = yesShares, output_reserve = yesReserve
        //    - If position is NO: input_reserve = noShares, output_reserve = noReserve
        // 5. Calculate tokens to return:
        //    tokens = (shareAmount * output_reserve) / (input_reserve - shareAmount)
        // 6. Update market state:
        //    - If position is YES:
        //      yesReserve -= tokens
        //      yesShares -= shareAmount
        //    - If position is NO:
        //      noReserve -= tokens
        //      noShares -= shareAmount
        // 7. Update user's position in positions mapping:
        //    - If position is YES: positions[proposalId][msg.sender].yesShares -= shareAmount
        //    - If position is NO: positions[proposalId][msg.sender].noShares -= shareAmount
        // 8. Transfer tokens of governanceTokens to user
        // 9. Emit SharesSold event
    }

    /// @notice Resolves a market with the final outcome
    /// @param proposalId The ID of the proposal associated with the market
    /// @param outcome The final outcome of the market
    /// @dev Only the oracle can call this function
    function resolveMarket(bytes32 proposalId, Outcome outcome) external {
        // TODO: Implement market resolution logic
        // 1. Ensure caller is oracle
        // 2. Retrieve market info for proposalId
        // 3. Ensure market exists and is not already resolved
        // 4. Update market:
        //    - resolved = true
        //    - resolutionTime = current block timestamp
        //    - outcome = outcome
        // 5. Emit MarketResolved event
    }

    /// @notice Allows a user to claim their winnings from a resolved market
    /// @param proposalId The ID of the proposal associated with the market
    function claimWinnings(bytes32 proposalId) external {
        // TODO: Implement winnings claim logic
        // 1. Retrieve market info for proposalId
        // 2. Ensure market is resolved
        // 3. Retrieve user's position
        // 4. Calculate winnings based on outcome and user's position:
        //    - If outcome is Yes, winnings = user's yesShares * (totalReserve / totalYesShares)
        //    - If outcome is No, winnings = user's noShares * (totalReserve / totalNoShares)
        // 5. Clear user's position
        // 6. Transfer winnings to user
        // 7. Update market's totalFeesCollected (if applicable)
    }

    /// @notice Calculates the current price of YES shares in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param position Type of share (true for YES shares, false for NO shares)
    /// @return The price of YES shares as a fixed-point number with 6 decimal places
    function getPrice(
        bytes32 proposalId,
        bool position
    ) public view returns (uint256) {
        // TODO: Implement price calculation logic
        // 1. Retrieve market info for proposalId
        // 2. Ensure market exists
        // 3. Determine input_reserve and output_reserve based on position:
        //    - If position is YES: input_reserve = yesReserve, output_reserve = yesShares
        //    - If position is NO: input_reserve = noReserve, output_reserve = noShares
        // 4. Calculate price:
        //    price = (input_reserve * 10^6) / output_reserve
        // 5. Return calculated price
    }

    /// @notice Retrieves the current position of a user in a market
    /// @param proposalId The ID of the proposal associated with the market
    /// @param user The address of the user
    /// @return The user's position (number of YES and NO shares)
    function getPosition(
        bytes32 proposalId,
        address user
    ) external view returns (Position memory) {
        // TODO: Implement position retrieval logic
    }

    /// @notice Allows the DAO to update the oracle address
    /// @param newOracle The address of the new oracle
    /// @dev Only the DAO contract can call this function
    function updateOracle(address newOracle) external {
        // TODO: Implement oracle update logic
    }

    function getMarketInfo(
        bytes32 proposalId
    ) external view override returns (MarketInfo memory) {}
}
