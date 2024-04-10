// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";

interface IPoolLotteryStorage {
  /// @notice thown on try to add player that is already in the players list
  error IPoolLotteryStorage__AlreadyAPlayer();

  /// @notice thown on try to perform actions that need the player to be in the players list. e.g remove, withdraw
  error IPoolLotteryStorage__NotAPlayer();

  /// @notice thrown on try to set a winner but is already set
  error IPoolLotteryStorage__WinnerAlreadySet();

  /// @notice thrown on try to withdraw after the winner is set but the funds are not sent to the winner address
  error IPoolLotteryStorage__WithdrawOnlyToWinner(address winner);

  /// @notice thrown when add player fails for any reason
  error IPoolLotteryStorage__FailedToAddPlayer(address player);

  /// @notice thrown when remove player fails for any reason
  error IPoolLotteryStorage__FailedToRemovePlayer(address player);

  /// @notice withdraw money from the storage
  /// @param amount the amount of tokens to be withdrawn
  /// @param to the address to send the tokens
  function withdraw(uint256 amount, address to) external;

  /// @notice remove player from the lottery
  function removePlayer(address player) external;

  /// @notice add new player to the lottery
  function addPlayer(address player) external;

  /// @notice set the status of the lottery
  /// @param status the new status to be set
  function setStatus(LotteryStatus status) external;

  /// @notice set the winner of the lottery
  /// @param winner the new winner to be set
  function setWinner(address winner) external;

  /// @notice Get the current Lottery Status
  function getStatus() external view returns (LotteryStatus);

  /// @notice Get the current Lottery Players
  function getPlayers() external view returns (address[] memory);

  /// @notice check if player is in the lottery
  /// @return _ true if player is in the players list, otherwise false
  function containsPlayer(address player) external view returns (bool);

  /// @notice Get the Lottery Winner
  function getWinner() external view returns (address);

  /// @notice Get the Lottery Ticket Price
  function getTicketPrice() external view returns (uint256 price, uint8 decimals);

  /// @notice Get the Lottery Token
  function getLotteryToken() external view returns (IERC20);

  /// @notice Get the Lottery End Date
  /// @return _ the end date of the lottery in seconds
  function getLotteryEndDate() external view returns (uint256);
}
