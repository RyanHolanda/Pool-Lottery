// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {LotteryStatus} from "src/types/LotteryStatus.sol";

/// @dev Helper library for checking lottery status.
library SafeLotteryStatus {
  function isClosed(LotteryStatus status) internal pure returns (bool) {
    return status == LotteryStatus.CLOSED;
  }

  function isOpen(LotteryStatus status) internal pure returns (bool) {
    return status == LotteryStatus.OPEN;
  }

  function isFinished(LotteryStatus status) internal pure returns (bool) {
    return status == LotteryStatus.FINISHED;
  }

  function isFailed(LotteryStatus status) internal pure returns (bool) {
    return status == LotteryStatus.FAILED;
  }
}
