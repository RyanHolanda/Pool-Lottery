// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Storage for PoolLottery. values that should keep
 * between Pool Lottery contract changes/upgrades(New Deploy),
 * should be located here.
 *
 */
contract PoolLotteryStorage is IPoolLotteryStorage, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  LotteryStatus private s_status = LotteryStatus.OPEN;
  EnumerableSet.AddressSet private s_players;
  address private s_winner;

  uint256 private immutable i_ticketPriceInTokenAmount;
  IERC20 private immutable i_lotteryToken;
  uint256 private immutable i_lotteryEndDate;

  /**
   * @dev The @param owner will belong to the PoolLotteryManager at first.
   * But it should be updated to belong to the current PoolLottery implementation
   *
   * So the real owner of this contract will be the PoolLottery contract.
   * Every time the PoolLottery contract changes,the ownership will be set to
   * the current PoolLottery implementation.
   *
   */
  constructor(
    uint256 ticketPriceInTokenAmountWithDecimals,
    IERC20 lotteryToken,
    uint256 lotteryDuration,
    address owner
  ) Ownable(owner) {
    i_ticketPriceInTokenAmount = ticketPriceInTokenAmountWithDecimals;
    i_lotteryToken = lotteryToken;

    i_lotteryEndDate = (block.timestamp + lotteryDuration); // solhint-disable-line not-rely-on-time
  }

  /// @inheritdoc IPoolLotteryStorage
  function withdraw(uint256 amount, address to) external onlyOwner {
    address winner = s_winner;

    if (!s_players.contains(to)) revert IPoolLotteryStorage__NotAPlayer();
    if (winner != address(0) && to != winner) revert IPoolLotteryStorage__WithdrawOnlyToWinner(winner);

    i_lotteryToken.safeTransfer(to, amount);
  }

  /// @inheritdoc IPoolLotteryStorage
  function removePlayer(address player) external override onlyOwner {
    if (!s_players.contains(player)) revert IPoolLotteryStorage__NotAPlayer();
    bool success = EnumerableSet.remove(s_players, player);

    if (!success) revert IPoolLotteryStorage__FailedToRemovePlayer(player);
  }

  /// @inheritdoc IPoolLotteryStorage
  function addPlayer(address player) external override onlyOwner {
    if (s_players.contains(player)) revert IPoolLotteryStorage__AlreadyAPlayer();
    bool success = s_players.add(player);

    if (!success) revert IPoolLotteryStorage__FailedToAddPlayer(player);
  }

  /// @inheritdoc IPoolLotteryStorage
  function setStatus(LotteryStatus status) external override onlyOwner {
    s_status = status;
  }

  /// @inheritdoc IPoolLotteryStorage
  function setWinner(address winner) external override onlyOwner {
    if (s_winner != address(0)) revert IPoolLotteryStorage__WinnerAlreadySet();
    if (!s_players.contains(winner)) revert IPoolLotteryStorage__NotAPlayer();

    s_winner = winner;
  }

  /// @inheritdoc IPoolLotteryStorage
  function getStatus() external view override returns (LotteryStatus) {
    return s_status;
  }

  /// @inheritdoc IPoolLotteryStorage
  function getPlayers() external view override returns (address[] memory) {
    return s_players.values();
  }

  /// @inheritdoc IPoolLotteryStorage
  function containsPlayer(address player) external view override returns (bool) {
    return s_players.contains(player);
  }

  /// @inheritdoc IPoolLotteryStorage
  function getWinner() external view override returns (address) {
    return s_winner;
  }

  /// @inheritdoc IPoolLotteryStorage
  function getTicketPrice() external view override returns (uint256 price, uint8 decimals) {
    address ticketToken = address(i_lotteryToken);
    IERC20Metadata ticketTokenMetadata = IERC20Metadata(ticketToken);

    price = i_ticketPriceInTokenAmount;
    decimals = ticketTokenMetadata.decimals();
  }

  /// @inheritdoc IPoolLotteryStorage
  function getLotteryToken() external view override returns (IERC20) {
    return i_lotteryToken;
  }

  /// @inheritdoc IPoolLotteryStorage
  function getLotteryEndDate() external view override returns (uint256) {
    return i_lotteryEndDate;
  }
}
