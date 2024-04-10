// SPDX-License-Identifier:MIT
// solhint-disable one-contract-per-file
pragma solidity 0.8.25;

import {Math} from "src/libraries/Math.sol";
import {RNGConsumerHarness} from "test/harnesses/RNGConsumerHarness.t.sol";
import {BaseTest} from "test/BaseTest.t.sol";

contract RNGConsumerTest is BaseTest {
  RNGConsumerHarness public cut;

  function setUp() public override {
    super.setUp();

    cut = new RNGConsumerHarness({
      callbackGasLimit: VRF_CALLBACK_GAS_LIMIT,
      minimumRequestConfirmations: VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      linkTokenAddress: address(LINK_TOKEN),
      vrfV2Wrapper: address(VRF_V2_WRAPPER_MOCK),
      linkPool: address(LINK_POOL)
    });

    LINK_POOL.addSpender(address(cut));
  }

  function test_fulfillRandomWords_multiplyTheRandomWordsReceived(
    uint8 randomNumber1,
    uint8 randomNumber2,
    uint8 randomNumber3,
    uint8 randomNumber4
  ) public {
    uint256[] memory randomWords = new uint256[](4);
    randomWords[0] = randomNumber1;
    randomWords[1] = randomNumber2;
    randomWords[2] = randomNumber3;
    randomWords[3] = randomNumber4;

    uint256 expectedOutcome = Math.multiplyBetween(randomWords);

    vm.startPrank(address(VRF_V2_WRAPPER_MOCK));
    cut.exposedFulfillRandomWords(0, randomWords);
    vm.stopPrank();

    assert(cut.randomNumberReceived() == expectedOutcome);
  }
}
