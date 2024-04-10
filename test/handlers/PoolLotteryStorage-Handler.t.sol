// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolLotteryStorageHandler is IPoolLotteryStorage {
  IPoolLotteryStorage public poolLotteryStorage;
  uint256 public constant TICKET_PRICE = 100;
  uint256 public constant LOTTERY_DURATION = 10;
  ERC20Mock public immutable LOTTERY_TOKEN = new ERC20Mock();

  constructor() {
    poolLotteryStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: LOTTERY_TOKEN,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    LOTTERY_TOKEN.mint(address(poolLotteryStorage), type(uint256).max);
  }

  function withdraw(uint256 amount, address to) external override {
    if (!poolLotteryStorage.containsPlayer(to)) poolLotteryStorage.addPlayer(to);
    poolLotteryStorage.withdraw(amount, to);
  }

  function removePlayer(address player) external override {
    if (!poolLotteryStorage.containsPlayer(player)) poolLotteryStorage.addPlayer(player);
    poolLotteryStorage.removePlayer(player);
  }

  function addPlayer(address player) external override {
    poolLotteryStorage.addPlayer(player);
  }

  function setStatus(LotteryStatus status) external override {
    poolLotteryStorage.setStatus(status);
  }

  function setWinner(address winner) external override {
    if (!poolLotteryStorage.containsPlayer(winner)) poolLotteryStorage.addPlayer(winner);
    poolLotteryStorage.setWinner(winner);
  }

  function getStatus() external view override returns (LotteryStatus) {
    return poolLotteryStorage.getStatus();
  }

  function getPlayers() external view override returns (address[] memory) {
    return poolLotteryStorage.getPlayers();
  }

  function containsPlayer(address player) external view override returns (bool) {
    return poolLotteryStorage.containsPlayer(player);
  }

  function getWinner() external view override returns (address) {
    return poolLotteryStorage.getWinner();
  }

  function getTicketPrice() external view override returns (uint256 price, uint8 decimals) {
    return poolLotteryStorage.getTicketPrice();
  }

  function getLotteryToken() external view override returns (IERC20) {
    return poolLotteryStorage.getLotteryToken();
  }

  function getLotteryEndDate() external view override returns (uint256) {
    return poolLotteryStorage.getLotteryEndDate();
  }

  /// @dev A dummy test to not include this file in coverage report
  function test() public pure {
    assert(true);
  }
}
