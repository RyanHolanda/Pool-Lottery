// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {GasSnapshot} from "@forge-gas-snapshot/src/GasSnapshot.sol";
import {RNGConsumerHarness} from "test/harnesses/RNGConsumerHarness.t.sol";

contract RNGConsumerGasTest is BaseTest, GasSnapshot {
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

  function testGas_rawRequestRandomNumber() public {
    setCheckMode(true);

    vm.startPrank(address(cut));

    snapStart("RNGConsumer_rawRequestRandomNumber");
    cut.rawRequestRandomNumber();
    snapEnd();

    vm.stopPrank();
  }

  function testGas_requestRandomNumber() public {
    setCheckMode(true);

    snapStart("RNGConsumer_requestRandomNumber");
    cut.exposedRequestRandomNumber();
    snapEnd();
  }

  function testGas_fulfillRandomWords_success() public {
    uint256[] memory randomWords = new uint256[](VRF_NUM_WORDS_TO_REQUEST);
    for (uint256 i = 0; i < VRF_NUM_WORDS_TO_REQUEST; i++) {
      randomWords[i] = i + 1;
    }

    setCheckMode(true);
    vm.startPrank(address(VRF_V2_WRAPPER_MOCK));

    snapStart("RNGConsumer_fulfillRandomWords");
    cut.exposedFulfillRandomWords(1, randomWords);
    snapEnd();

    vm.stopPrank();
    assertFalse(cut.requestHasFailed());
  }

  function testGas_fulfillRandomWords_error() public {
    uint256[] memory randomWords = new uint256[](VRF_NUM_WORDS_TO_REQUEST);
    for (uint256 i = 0; i < VRF_NUM_WORDS_TO_REQUEST; i++) {
      randomWords[i] = UINT256_MAX; // it will result in a overflow, which is expected to make the fulfillRandomWords fail
    }

    setCheckMode(true);
    vm.startPrank(address(VRF_V2_WRAPPER_MOCK));

    snapStart("RNGConsumer_fulfillRandomWords_error");
    cut.exposedFulfillRandomWords(1, randomWords);
    snapEnd();

    vm.stopPrank();
    assertTrue(cut.requestHasFailed());
  }
}
