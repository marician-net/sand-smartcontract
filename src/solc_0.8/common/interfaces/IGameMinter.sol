//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./IGameToken.sol";

interface IGameMinter {
    function createGame(
        address to,
        IGameToken.Update calldata creation,
        address editor,
        uint64 subId
    ) external returns (uint256 gameId);

    function updateGame(
        uint256 gameId,
        IGameToken.Update memory update
    ) external returns (uint256 newId);
}
