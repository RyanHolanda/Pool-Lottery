// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {StdInvariant} from "@forge/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolLotteryStorageHandler} from "test/handlers/PoolLotteryStorage-Handler.t.sol";

contract PoolLotteryStorageStatefulFuzzTest is StdInvariant, BaseTest {
  PoolLotteryStorageHandler public handler;

  function setUp() public override {
    handler = new PoolLotteryStorageHandler();

    targetContract(address(handler));
  }

  function invariant_ticketPriceShouldNeverChange() public {
    (uint256 ticketPrice, ) = handler.getTicketPrice();
    assertEq(ticketPrice, handler.TICKET_PRICE());
  }

  function invariant_lotteryEndDateShouldNeverChange() public {
    uint256 lotteryDuration = handler.getLotteryEndDate();
    assertEq(lotteryDuration, handler.LOTTERY_DURATION() + block.timestamp); // solhint-disable-line not-rely-on-time
  }

  function invariant_lotteryTokenShouldNeverChange() public view {
    IERC20 lotteryToken = handler.getLotteryToken();
    assert(lotteryToken == handler.LOTTERY_TOKEN());
  }

  /// @dev A dummy test to not include this file in coverage report
  function test() public pure override {
    assert(true);
  }
}
