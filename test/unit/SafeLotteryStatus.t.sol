// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeLotteryStatus} from "src/libraries/SafeLotteryStatus.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {BaseTest} from "test/BaseTest.t.sol";

contract SafeLotteryStatusTest is BaseTest {
  function testSafeLotteryStatusIsOpen() public {
    LotteryStatus status = LotteryStatus.OPEN;
    assertTrue(SafeLotteryStatus.isOpen(status));
  }

  function testSafeLotteryStatusIsClosed() public {
    LotteryStatus status = LotteryStatus.CLOSED;
    assertTrue(SafeLotteryStatus.isClosed(status));
  }

  function testSafeLotteryStatusIsFinished() public {
    LotteryStatus status = LotteryStatus.FINISHED;
    assertTrue(SafeLotteryStatus.isFinished(status));
  }

  function testSafeLotteryStatusIsFailed() public {
    LotteryStatus status = LotteryStatus.FAILED;
    assertTrue(SafeLotteryStatus.isFailed(status));
  }
}
