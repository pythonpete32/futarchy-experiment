# Futarchy Experiment

## Background on Futarchy

Futarchy is a form of governance proposed by economist Robin Hanson. The core idea is to use prediction markets to inform and make policy decisions. In a futarchy system, people would "vote on values, but bet on beliefs." This means:

1. Stakeholders vote to determine what outcomes they want (e.g., "increase GDP" or "improve education").
2. Prediction markets are then created to forecast the effects of proposed policies on these desired outcomes.
3. The policies that the markets predict will best achieve the desired outcomes are then implemented.

The theory behind futarchy is that it harnesses the wisdom of crowds and the incentive structure of markets to make more informed and effective decisions than traditional voting systems.

## Project Overview

This repository contains a Solidity implementation of a futarchy-based prediction market system designed for DAO governance. The goal of this experiment is to explore whether we can bootstrap a DAO using only futarchy, with the specific objective of increasing the value of the DAO's token.

### Key Features

- Creation of prediction markets for DAO proposals
- Trading of YES/NO shares for each proposal
- Constant Product Market Maker (CPMM) model for liquidity provision
- Winning share redemption mechanism

## Experiment Goal and Mechanism

The goal of this experiment is to bootstrap a DAO using only futarchy, with the objective of increasing the value of the DAO's token. Here's how it's supposed to work:

1. **Proposal Creation**: The DAO creates a proposal for a potential action (e.g., "Invest in Project X").
2. **Market Creation**: A futarchy market is created for this proposal using the `createMarket` function. This sets up YES and NO markets for the proposal.
3. **Trading**: DAO token holders can buy and sell shares in both the YES and NO markets using the `buyShares` and `sellShares` functions. They are essentially betting on whether the proposal will increase the DAO's token value if implemented.
4. **Price Discovery**: As trading occurs, the relative prices of YES and NO shares indicate the market's prediction of the proposal's impact on token value. The `getSharesOutAmount` and `getTokensOutAmount` functions can be used to check current prices and expected trade outcomes.
5. **Decision Making**: After the trading period, the market prices are used to make the decision. If YES shares are trading higher, the proposal is accepted; if NO shares are higher, it's rejected.
6. **Implementation**: The DAO implements the decision (or not) based on the market outcome.
7. **Outcome Measurement**: After a predetermined period, the impact on the DAO's token value is measured.
8. **Market Resolution**: The oracle calls `resolveMarket` to set the final outcome based on the actual impact on token value.
9. **Profit Distribution**: Traders who bet correctly can claim their winnings using the `claimWinnings` function.

This mechanism is designed to:
- Align incentives: Traders are incentivized to make accurate predictions to profit.
- Aggregate information: The market prices aggregate diverse information and opinions about the proposal's potential impact.
- Guide decision-making: The DAO can make decisions based on market-aggregated information rather than traditional voting.
- Reward accuracy: Correct predictions are rewarded, incentivizing careful analysis and information sharing.

By focusing all decisions on increasing token value, the hypothesis is that the DAO will make better decisions over time, leading to increased value for all token holders.


## Smart Contract: FutarchyMarket

The core of this experiment is the `FutarchyMarket` smart contract. Here's an overview of its main components:

### State Variables

- `governanceToken`: The ERC20 token used for trading in the market
- `INITIAL_LIQUIDITY`: Constant amount of initial liquidity added to both YES and NO markets
- `PRICE_PRECISION`: Precision factor for price calculations
- `daoAddress`: Address of the DAO contract
- `oracle`: Address authorized to resolve markets
- `markets`: Mapping from proposalId to MarketInfo
- `positions`: Mapping from proposalId to user address to their position

### Key Functions

1. `createMarket(bytes32 proposalId, uint256 tradingPeriod)`: Creates a new market for a given proposal
2. `buyShares(bytes32 proposalId, bool position, uint256 amount)`: Allows users to buy shares in a market
3. `sellShares(bytes32 proposalId, bool position, uint256 shareAmount)`: Allows users to sell shares in a market
4. `resolveMarket(bytes32 proposalId, Outcome outcome)`: Resolves a market with the final outcome
5. `claimWinnings(bytes32 proposalId)`: Allows users to claim their winnings from a resolved market
6. `getSharesOutAmount(bytes32 proposalId, bool position, uint256 amount)`: Calculates the amount of shares that would be received for a given input amount
7. `getTokensOutAmount(bytes32 proposalId, bool position, uint256 shareAmount)`: Calculates the amount of tokens that would be received for selling a given amount of shares
8. `calculateWinnings(bytes32 proposalId, address user)`: Calculates the winnings for a user in a given market
9. `getPosition(bytes32 proposalId, address user)`: Retrieves the current position of a user in a market
10. `updateOracle(address newOracle)`: Allows the DAO to update the oracle address
11. `getMarketInfo(bytes32 proposalId)`: Retrieves the market information for a given proposalId


## Market Mechanism

This implementation uses a Constant Product Market Maker (CPMM) model, similar to Uniswap v1 but without fees. This ensures continuous liquidity for trading while allowing prices to adjust based on market activity.

## Quick Start

This project uses [Foundry](https://book.getfoundry.sh/), a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

To get started:

1. Clone the repository:
   ```
   git clone https://github.com/pythonpete32/futarchy-experiment.git
   cd futarchy-experiment
   ```

2. Install Foundry:
   ```
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. Build the project:
   ```
   forge build
   ```

4. Run tests:
   ```
   forge test
   ```

5. Generate test coverage report:
   ```
   forge coverage --report lcov
   genhtml lcov.info -o coverage_report
   ```
   This will generate a coverage report in the `coverage_report` directory. Open `coverage_report/index.html` in your browser to view the report.

6. Deploy contracts:
   ```
   forge create src/FutarchyMarket.sol:FutarchyMarket --constructor-args <GOVERNANCE_TOKEN_ADDRESS> <DAO_ADDRESS> <ORACLE_ADDRESS> --private-key <YOUR_PRIVATE_KEY>
   ```

For more detailed information on using Foundry, please refer to the [Foundry Book](https://book.getfoundry.sh/).

## Contributing

We welcome contributions to the Futarchy Experiment! Please feel free to submit issues, create pull requests, or fork the repository to make your own changes.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Disclaimer

This is an experimental implementation of futarchy for research and exploration purposes. ***It should not be used in production***