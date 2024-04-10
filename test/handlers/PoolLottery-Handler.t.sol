/// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {Test} from "@forge/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {BaseTest} from "test/BaseTest.t.sol";

contract PoolLotteryHandler is BaseTest, IPoolLottery {
  using Strings for uint256;

  IPoolLottery public poolLottery;
  PoolLotteryStorage public poolStorage;

  constructor() {
    setUp();

    poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    poolLottery = new PoolLottery(
      VRF_CALLBACK_GAS_LIMIT,
      VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      address(LINK_TOKEN),
      address(VRF_V2_WRAPPER_MOCK),
      address(LINK_POOL),
      address(poolStorage),
      address(this)
    );
    poolStorage.transferOwnership(address(poolLottery));
  }

  function enterPool() external override randomUser {
    MOCK_ERC_20.approve(address(poolLottery), UINT256_MAX);
    MOCK_ERC_20.mint(lastRandomUser, TICKET_PRICE);

    poolLottery.enterPool();
  }

  function exitPool() external override useLastRandomUser {
    poolLottery.exitPool();
  }

  function transferFundsToWinner() external override {
    poolLottery.transferFundsToWinner();
  }

  function chooseWinner() external override {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();

    vm.warp(lotteryEndDate + 2 hours);
    poolLottery.chooseWinner();
  }

  function transferStorageOwnership(address /* newOwner */) external override {
    PoolLotteryStorage(address(poolStorage)).transferOwnership(address(poolLottery));
  }

  /// @dev A dummy test to not include this file in coverage report
  function test() public pure override {
    assert(true);
  }
}
