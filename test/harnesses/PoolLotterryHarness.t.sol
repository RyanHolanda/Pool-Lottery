// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";

contract PoolLotteryHarness is PoolLottery, BaseTest {
  constructor()
    PoolLottery(
      VRF_CALLBACK_GAS_LIMIT,
      VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      address(LINK_TOKEN),
      address(VRF_V2_WRAPPER),
      address(LINK_POOL),
      address(
        new PoolLotteryStorage({
          ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
          lotteryToken: MOCK_ERC_20,
          lotteryDuration: LOTTERY_DURATION,
          owner: address(this)
        })
      ),
      address(this)
    )
  {
    mintMockERC20(address(msg.sender), 2e29);

    vm.startPrank(msg.sender);
    MOCK_ERC_20.approve(address(this), UINT256_MAX);
    vm.stopPrank();

    LINK_POOL.addSpender(address(this));
  }

  function exposed_onReceiveRandomNumber(uint256 randomNumber) external {
    _onReceiveRandomNumber(randomNumber);
  }

  function exposed_onFailToGenerateRandomNumber() external {
    _onFailToGenerateRandomNumber();
  }
}
