// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {VRFV2WrapperInterface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFV2WrapperInterface.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract VRFV2WrapperMock is VRFV2WrapperInterface, IERC677Receiver {
  uint256 private _lastRequestId;
  uint256[] private _randomWordsToReturn = [3, 2, 2];

  function onTokenTransfer(address sender, uint256 /* amount*/, bytes calldata /* data */) external override {
    VRFV2WrapperConsumerBase c;
    ++_lastRequestId;
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = sender.call(
      abi.encodeWithSelector(c.rawFulfillRandomWords.selector, _lastRequestId, _randomWordsToReturn)
    );

    require(success, "Failed to call fulfill random words"); // solhint-disable-line custom-errors
  }

  function overrideRandomWords(uint256[] memory randomWords) external {
    _randomWordsToReturn = randomWords;
  }

  function lastRequestId() external view override returns (uint256) {
    return _lastRequestId;
  }

  function randomWordsToReceive() external view returns (uint256[] memory) {
    return _randomWordsToReturn;
  }

  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external pure override returns (uint256) {}

  function calculateRequestPrice(uint32 /* _callbackGasLimit */) external pure override returns (uint256) {
    return 2e18;
  }

  /// @dev A dummy test to not include this file in coverage report
  function test() public pure {
    assert(true);
  }
}
