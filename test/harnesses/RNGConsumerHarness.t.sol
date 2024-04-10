// SPDX-License-Identifier:MIT
pragma solidity 0.8.25;

import {RNGConsumer} from "src/contracts/RNGConsumer.sol";

// solhint-disable no-inline-assembly
contract RNGConsumerHarness is RNGConsumer {
  bool private hasFailed;
  uint256 private lastRandomNumberReceived;

  uint32 private constant VRF_CALLBACK_GAS_LIMIT = 2_500_000;
  uint256 private constant VRF_MINIMUM_REQUEST_CONFIRMATIONS = 2;
  event OnReceiveRandomNumberCalled();

  constructor(
    uint32 callbackGasLimit,
    uint16 minimumRequestConfirmations,
    address linkTokenAddress,
    address vrfV2Wrapper,
    address linkPool
  ) RNGConsumer(callbackGasLimit, minimumRequestConfirmations, linkTokenAddress, vrfV2Wrapper, linkPool) {}

  function exposedRequestRandomNumber() public {
    _requestRandomNumber();
  }

  function exposedFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) public {
    fulfillRandomWords(requestId, randomWords);
  }

  function requestHasFailed() public view returns (bool failed) {
    assembly {
      failed := tload(hasFailed.slot)
    }
  }

  function randomNumberReceived() public view returns (uint256 randomNumber) {
    assembly {
      randomNumber := tload(lastRandomNumberReceived.slot)
    }
  }

  function _onReceiveRandomNumber(uint256 randomNumber) internal override {
    assert(lastRandomNumberReceived == 0);

    assembly {
      tstore(lastRandomNumberReceived.slot, randomNumber)
    }

    emit OnReceiveRandomNumberCalled();
  }

  function _onFailToGenerateRandomNumber() internal virtual override {
    assert(!requestHasFailed());

    assembly {
      tstore(hasFailed.slot, true)
    }
  }
}
