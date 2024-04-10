// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IPoolLottery {
  /// @notice emitted when the user boughts a ticket
  event IPoolLottery__TicketBought(address indexed user, uint256 indexed ticketPrice);

  /// @notice emitted when the user exits the pool
  event IPoolLottery__Exited(address indexed user, uint256 indexed ticketPrice);

  /// @notice emitted when the winner is chosen
  event IPoolLottery__WinnerChosen(address indexed winner);

  /// @notice emitted once the contract starts choosing a winner
  event IPoolLottery__ChoosingWinner();

  /**
   * @notice emitted when the contract does not behave as expected(Like failing to choose a winner)
   * and should block all actions other than exitPool.
   */
  event IPoolLottery__Failed();

  /// @notice thrown on try to buy a ticket but the user has already joined
  error IPoolLottery__AlreadyJoined();

  /// @notice thrown on try to perform actions that need the lottery status to be open. e.g enterPool or exitPool
  error IPoolLottery__NotOpen();

  /// @notice thrown on try to perform actions that need the lottery status to be finished. e.g send funds to the winner
  error IPoolLottery__NotFinished();

  /// @notice thrown on try to exit the pool but the user has not joined yet
  error IPoolLottery__NotJoined();

  /// @notice thown on try to perform actions that need the current date to be less than the end date. e.g enterPool or exitPool
  error IPoolLottery__EndDateReached();

  /// @notice thrown on try to choose a winner but the winner has already been chosen
  error IPoolLottery__WinnerAlreadyChosen();

  /// @notice thrown on try to interact with winner address but the winner address is invalid. e.g address zero
  error IPoolLottery__InvalidWinner();

  /// @notice thrown on try to choose a winner but there aren't at least 2 players in the pool
  error IPoolLottery__NotEnoughPlayers();

  /// @notice thrown on try to perform actions that need the current date to be greater than the end date. e.g chooseWinner
  error IPoolLottery__EndDateNotReached();

  /// @notice thrown on try to buy a ticket but the user does not have enough balance to pay for the ticket
  error IPoolLottery__NotEnoughBalance();

  /// @notice buys a ticket to enter the pool lottery
  function enterPool() external;

  /// @notice exit the lottery pool and get back the ticket price
  function exitPool() external;

  /**
   * @notice withdraw money from the pool once the winner is chosen.
   *
   * @dev Only the winner or the contract itself should be able to perform this
   */
  function transferFundsToWinner() external;

  /// @notice choose a winner from the pool
  function chooseWinner() external;

  /// @notice transfer the storage ownership to another contract
  function transferStorageOwnership(address newOwner) external;
}
