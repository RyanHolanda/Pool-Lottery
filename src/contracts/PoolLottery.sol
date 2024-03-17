// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PoolLottery is IPoolLottery, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  EnumerableSet.AddressSet private players;
  uint256 private immutable i_ticketPriceInTokenAmount;
  IERC20 private immutable i_lotteryToken;

  constructor(uint256 ticketPriceInTokenAmountWithDecimals, IERC20 lotteryToken) {
    i_ticketPriceInTokenAmount = ticketPriceInTokenAmountWithDecimals;
    i_lotteryToken = lotteryToken;
  }

  /// @inheritdoc IPoolLottery
  function exitPool() external override {}

  /// @inheritdoc IPoolLottery
  function withdraw() external override {}

  /// @inheritdoc IPoolLottery
  function getTicketPrice() external view override returns (uint256) {
    return i_ticketPriceInTokenAmount;
  }

  /// @inheritdoc IPoolLottery
  function getPlayers() external view override returns (address[] memory) {
    return players.values();
  }

  /// @inheritdoc IPoolLottery
  function getLotteryToken() external view override returns (IERC20) {
    return i_lotteryToken;
  }

  /// @inheritdoc IPoolLottery
  function chooseWinner() public virtual {}

  /// @inheritdoc IPoolLottery
  function enterPool() public virtual {
    if (players.contains(msg.sender)) revert IPoolLottery__AlreadyJoined();

    players.add(msg.sender);

    i_lotteryToken.safeTransferFrom(msg.sender, address(this), i_ticketPriceInTokenAmount);

    emit IPoolLottery__TicketBought(msg.sender, i_ticketPriceInTokenAmount);
  }
}
