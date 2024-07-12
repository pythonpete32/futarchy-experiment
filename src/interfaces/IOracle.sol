interface IOracle {
    function resolveMarket(bytes32 proposalId, IMarket.Outcome outcome) external;
}