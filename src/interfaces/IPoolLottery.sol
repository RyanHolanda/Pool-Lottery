// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolLottery {
  /// @notice emitted when the user boughts a ticket
  event IPoolLottery__TicketBought(address indexed user, uint256 indexed ticketPrice);

  /// @notice thrown on try to buy a ticket but the user has already joined
  error IPoolLottery__AlreadyJoined();

  /// @notice buys a ticket to enter the pool lottery
  function enterPool() external;

  /// @notice exit the lottery pool and get back the ticket price
  function exitPool() external;

  /// @notice withdraw money from the pool once the winner is chosen. Only the winner can perform this
  function withdraw() external;

  /// @notice choose a winner from the pool
  function chooseWinner() external;

  /// @notice get the ticket price
  function getTicketPrice() external view returns (uint256);

  /// @notice get Players array
  function getPlayers() external view returns (address[] memory);

  /// @notice get lottery ticket token
  function getLotteryToken() external view returns (IERC20);
}
