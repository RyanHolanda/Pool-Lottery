//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLottery} from "src/contracts/PoolLottery.sol";
import {BaseTest} from "test/BaseTest.sol";

contract PoolLotteryTest is BaseTest {
  IPoolLottery public sut;

  modifier joinedPool() {
    vm.startPrank(USER);
    vm.deal(USER, 100 ether);
    MOCK_ERC_20.approve(address(sut), 1000 ether);
    sut.enterPool();
    vm.stopPrank();
    _;
  }

  function setUp() public override {
    sut = new PoolLottery({ticketPriceInTokenAmountWithDecimals: TICKET_PRICE, lotteryToken: MOCK_ERC_20});
    super.setUp();
  }

  function testEnterPoolRevertsIfUserHasAlreadyJoined() public joinedPool userAsSender {
    vm.expectRevert(IPoolLottery.IPoolLottery__AlreadyJoined.selector);
    sut.enterPool();
  }

  function testGetLotteryToken() public view {
    assert(sut.getLotteryToken() == MOCK_ERC_20);
  }
}
