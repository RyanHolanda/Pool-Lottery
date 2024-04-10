// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {SafeLotteryStatus} from "src/libraries/SafeLotteryStatus.sol";
import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {RNGConsumer} from "src/contracts/RNGConsumer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";

contract PoolLottery is IPoolLottery, ReentrancyGuard, RNGConsumer, Ownable {
  using SafeERC20 for IERC20;
  using SafeLotteryStatus for LotteryStatus;

  IPoolLotteryStorage private immutable i_poolStorage;
  uint256 private immutable i_ticketPriceInTokenAmount;
  IERC20 private immutable i_lotteryToken;
  uint8 private immutable i_lotteryTokenDecimals;
  uint256 private immutable i_lotteryEndDate;

  constructor(
    uint32 vrfCallbackGasLimit,
    uint16 vrfMinimumRequestConfirmations,
    address linkTokenAddress,
    address vrfV2Wrapper,
    address linkPool,
    address poolStorage,
    address poolLotteryManager
  )
    RNGConsumer(vrfCallbackGasLimit, vrfMinimumRequestConfirmations, linkTokenAddress, vrfV2Wrapper, linkPool)
    Ownable(poolLotteryManager)
  {
    i_poolStorage = IPoolLotteryStorage(poolStorage);
    (i_ticketPriceInTokenAmount, i_lotteryTokenDecimals) = i_poolStorage.getTicketPrice();
    i_lotteryToken = i_poolStorage.getLotteryToken();
    i_lotteryEndDate = i_poolStorage.getLotteryEndDate();
  }

  /// @inheritdoc IPoolLottery
  function transferStorageOwnership(address newOwner) external override onlyOwner {
    PoolLotteryStorage(address(i_poolStorage)).transferOwnership(newOwner);
  }

  /// @inheritdoc IPoolLottery
  function exitPool() external override nonReentrant {
    LotteryStatus lotteryStatus = i_poolStorage.getStatus();

    if (!i_poolStorage.containsPlayer(msg.sender)) revert IPoolLottery__NotJoined();
    if (lotteryStatus.isFailed()) return _rawExitPool();

    _revertIfAfterEndDate();
    _revertIfNotOpen();

    _rawExitPool();
  }

  /// @inheritdoc IPoolLottery
  function chooseWinner() external override {
    _revertIfNotOpen();

    address winner = i_poolStorage.getWinner();
    address[] memory players = i_poolStorage.getPlayers();

    if (winner != address(0)) revert IPoolLottery__WinnerAlreadyChosen();
    if (block.timestamp < i_lotteryEndDate) revert IPoolLottery__EndDateNotReached(); // solhint-disable-line not-rely-on-time
    if (players.length == 0) revert IPoolLottery__NotEnoughPlayers();

    i_poolStorage.setStatus(LotteryStatus.CLOSED);

    _requestRandomNumber();
    emit IPoolLottery__ChoosingWinner();
  }

  /// @inheritdoc IPoolLottery
  function enterPool() external override {
    _revertIfAfterEndDate();
    _revertIfNotOpen();

    if (i_lotteryToken.balanceOf(msg.sender) < i_ticketPriceInTokenAmount) revert IPoolLottery__NotEnoughBalance();
    if (i_poolStorage.containsPlayer(msg.sender)) revert IPoolLottery__AlreadyJoined();

    i_poolStorage.addPlayer(msg.sender);

    i_lotteryToken.safeTransferFrom(msg.sender, address(i_poolStorage), i_ticketPriceInTokenAmount);

    emit IPoolLottery__TicketBought(msg.sender, i_ticketPriceInTokenAmount);
  }

  /// @inheritdoc IPoolLottery
  function transferFundsToWinner() public override {
    LotteryStatus lotteryStatus = i_poolStorage.getStatus();
    address winner = i_poolStorage.getWinner();

    if (!lotteryStatus.isFinished()) revert IPoolLottery__NotFinished();
    if (winner == address(0)) revert IPoolLottery__InvalidWinner();

    i_poolStorage.withdraw(i_lotteryToken.balanceOf(address(i_poolStorage)), winner);
  }

  /// @inheritdoc RNGConsumer
  function _onReceiveRandomNumber(uint256 randomNumber) internal override {
    address[] memory players = i_poolStorage.getPlayers();
    address winner;

    if (randomNumber < players.length) {
      winner = players[randomNumber];
      i_poolStorage.setWinner(winner);
    } else {
      uint256 randomPlayerIndex = randomNumber % players.length;
      winner = players[randomPlayerIndex];

      i_poolStorage.setWinner(winner);
    }

    i_poolStorage.setStatus(LotteryStatus.FINISHED);
    emit IPoolLottery__WinnerChosen(winner);

    transferFundsToWinner();
  }

  /// @inheritdoc RNGConsumer
  function _onFailToGenerateRandomNumber() internal override {
    i_poolStorage.setStatus(LotteryStatus.FAILED);
    emit IPoolLottery__Failed();
  }

  /**
   * @dev be cautious when using this function
   * as it does not perform any check to
   * remove the player from the pool
   */
  function _rawExitPool() private {
    i_poolStorage.withdraw(i_ticketPriceInTokenAmount, msg.sender);
    i_poolStorage.removePlayer(msg.sender);

    emit IPoolLottery__Exited(msg.sender, i_ticketPriceInTokenAmount);
  }

  function _revertIfNotOpen() private view {
    LotteryStatus lotteryStatus = i_poolStorage.getStatus();
    if (!lotteryStatus.isOpen()) revert IPoolLottery__NotOpen();
  }

  function _revertIfAfterEndDate() private view {
    uint256 lotteryEndDate = i_poolStorage.getLotteryEndDate();
    if (block.timestamp >= lotteryEndDate) revert IPoolLottery__EndDateReached(); // solhint-disable-line not-rely-on-time
  }
}
