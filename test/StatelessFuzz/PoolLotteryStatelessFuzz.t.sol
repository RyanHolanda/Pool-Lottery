// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLottery} from "src/contracts/PoolLottery.sol";
import {BaseTest} from "test/BaseTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolLotteryStatelessFuzzTest is BaseTest {
  IPoolLottery public sut;

  uint256 public expectedPlayersCount = 0;
  uint256 public expectedSutBalance = 0;

  function setUp() public override {
    sut = new PoolLottery({ticketPriceInTokenAmountWithDecimals: TICKET_PRICE, lotteryToken: MOCK_ERC_20});
    MOCK_ERC_20.approve(address(sut), 1000 ether);
    super.setUp();
  }

  function testRightPlayerIsAddedToThePool(address user) public {
    if (user == address(0)) return;

    vm.startPrank(user);

    approveAndMintMockERC20(address(sut), user);
    sut.enterPool();

    vm.stopPrank();

    address[] memory players = sut.getPlayers();
    assertEq(players[expectedPlayersCount], user);

    ++expectedPlayersCount;
  }

  function testTransferFromIsCorrectWhenUserJoinsThePool(address user) public {
    if (user == address(0)) return;

    vm.startPrank(user);

    approveAndMintMockERC20(address(sut), user);
    vm.expectEmit(true, true, true, true);
    emit IERC20.Transfer(user, address(sut), TICKET_PRICE);
    sut.enterPool();

    vm.stopPrank();
  }

  function testTicketPriceIsSetCorrectly(uint256 ticketPrice) public {
    IPoolLottery lottery = new PoolLottery({
      ticketPriceInTokenAmountWithDecimals: ticketPrice,
      lotteryToken: MOCK_ERC_20
    });

    assertEq(lottery.getTicketPrice(), ticketPrice);
  }

  function testEnterPoolEmitsTicketBoughtEvent(address user) public {
    if (user == address(0)) return;

    vm.startPrank(user);
    approveAndMintMockERC20(address(sut), user);

    vm.expectEmit(true, true, false, false);
    emit IPoolLottery.IPoolLottery__TicketBought(user, TICKET_PRICE);
    sut.enterPool();

    vm.stopPrank();
  }

  function testEnterPoolSendTicketTokenToPool(address user) public {
    if (user == address(0)) return;

    vm.startPrank(user);

    approveAndMintMockERC20(address(sut), user);
    sut.enterPool();

    vm.stopPrank();

    expectedSutBalance += TICKET_PRICE;
    assertEq(MOCK_ERC_20.balanceOf(address(sut)), expectedSutBalance);
  }
}
