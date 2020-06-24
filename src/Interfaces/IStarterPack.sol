pragma solidity 0.6.5;


/// @title Interface for StarterPack contract

interface IStarterPack {
    event Purchase(address indexed from, address indexed to, uint256[4] catQuantities, uint256[5] gemQuantities);

    event SetPrices(uint256[4] prices);

    event Withdraw(address indexed to, uint256 amount);

    /// @notice A function for purchasing starter-packs.
    /// @param from Must be the tx sender or meta tx signer.
    /// @param to The address to send catalysts & gems to.
    /// @param catalystQuantities The amounts of each type of catalyst to send.
    /// @param gemQuantities The amounts of each type of gem to send.
    /// @param nonce A per-creator nonce, incremented to avoid reuse of signatures.
    /// @param signature A signed message specifying tx details.
    function purchase(
        address from,
        address to,
        uint256[4] calldata catalystQuantities,
        uint256[5] calldata gemQuantities,
        uint256 nonce,
        bytes calldata signature
    ) external payable;

    /// @notice Admin function to set the prices for packs.
    /// @dev throws if called by other than Admin
    function setPrices(uint256[4] calldata prices) external;

    /// @notice Admin function to withdraw all remaining
    /// catalysts & gems in this contract.
    /// @dev Throws if called by other than Admin.
    /// @dev If "to" is 0x0, the remaining tokens MAY be burned instead.
    /// @param to The address to send the tokens to.
    function withdrawAll(address to) external;
}
