// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {StdInvariant} from "@forge/StdInvariant.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {PoolLotteryHandler} from "test/handlers/PoolLottery-Handler.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";

contract PoolLotteryStatefulFuzz is StdInvariant, BaseTest {
  IPoolLottery public cut;
  PoolLotteryHandler public handler;

  function setUp() public override {
    handler = new PoolLotteryHandler();
    cut = handler;

    targetContract(address(cut));

    excludeSender(address(handler.poolStorage()));
  }

  function invariant_PoolBalanceShouldBeEquivalentToAmountOfPlayers() public {
    uint256 playersCount = getPlayers().length;
    IERC20 lotteryToken = getLotteryToken();

    assertEq(playersCount * getTicketPrice(), lotteryToken.balanceOf(address(handler.poolStorage())));
  }

  /// @dev A dummy test to not include this file in coverage report
  function test() public pure override {
    assert(true);
  }

  function getPlayers() internal view returns (address[] memory) {
    return handler.poolStorage().getPlayers();
  }

  function getLotteryToken() internal view returns (IERC20) {
    return handler.poolStorage().getLotteryToken();
  }

  function getTicketPrice() internal view returns (uint256 price) {
    (price, ) = handler.poolStorage().getTicketPrice();
  }
}
