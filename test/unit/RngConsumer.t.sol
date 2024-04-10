// SPDX-License-Identifier:MIT
// solhint-disable one-contract-per-file
pragma solidity 0.8.25;

import {RNGConsumer} from "src/contracts/RNGConsumer.sol";
import {RNGConsumerHarness} from "test/harnesses/RNGConsumerHarness.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {Math} from "src/libraries/Math.sol";

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

  function test_rawRequestRandomNumber_revertsIfTheCallerIsNotTheContractItSelf() public {
    vm.expectRevert(RNGConsumer.OnlyThisContractCanRequestFromOracle.selector);
    cut.rawRequestRandomNumber();
  }

  function test_rawRequestRandomNumber_revertsIfTheLinkTransferReturnFalse() public {
    vm.mockCall(address(LINK_TOKEN), abi.encodeWithSelector(LINK_TOKEN.transferFrom.selector), abi.encode(false));

    vm.expectRevert(RNGConsumer.FailedToReceiveLink.selector);

    vm.startPrank(address(cut));
    cut.rawRequestRandomNumber();
    vm.stopPrank();
  }

  function test_rawRequestRandomNumber_calls_requestRandomness_WithCorrectValues() public {
    /*
    This expect call is a way to verify that the passed parameters are what we expect.
    This is a call made by the chainlink VRFV2WrapperConsumerBase contract which use
    all parameters that we pass to requestRandomness function. If params are different,
    it will fail(the call will not be as expected).
    */
    vm.expectCall(
      address(LINK_TOKEN),
      abi.encodeWithSelector(
        LINK_TOKEN.transferAndCall.selector,
        address(VRF_V2_WRAPPER_MOCK),
        VRF_V2_WRAPPER_MOCK.calculateRequestPrice(VRF_CALLBACK_GAS_LIMIT),
        abi.encode(VRF_CALLBACK_GAS_LIMIT, VRF_MINIMUM_REQUEST_CONFIRMATIONS, VRF_NUM_WORDS_TO_REQUEST)
      )
    );

    vm.startPrank(address(cut));
    cut.rawRequestRandomNumber();
    vm.stopPrank();
  }

  function test_linkDoesNotKeepInTheContractIfRequestToOracleFails() public {
    vm.mockCallRevert(address(LINK_TOKEN), abi.encodeWithSelector(LINK_TOKEN.transferAndCall.selector), "Revert");

    cut.exposedRequestRandomNumber();

    assertEq(LINK_TOKEN.balanceOf(address(cut)), 0);
  }

  function test_correctAmountOfLinkIsTransferedToTheContract() public {
    uint256 expectedTransferAmount = VRF_V2_WRAPPER_MOCK.calculateRequestPrice(VRF_CALLBACK_GAS_LIMIT);

    vm.expectEmit();
    emit IERC20.Transfer({from: address(LINK_POOL), to: address(cut), value: expectedTransferAmount});

    cut.exposedRequestRandomNumber();
  }

  function test_requestRandomNumber_calls_onFailToGenerateRandomNumber_if_rawRequestRandomNumber_revert() public {
    vm.mockCallRevert(address(cut), abi.encodeWithSelector(RNGConsumer.rawRequestRandomNumber.selector), "Revert");

    cut.exposedRequestRandomNumber();

    assertTrue(cut.requestHasFailed(), "Request should fail and call `_onFailToGenerateRandomNumber`");
  }

  function test_requestRandomNumber_emits_event_if_rawRequestRandomNumber_revert() public {
    vm.mockCallRevert(address(cut), abi.encodeWithSelector(RNGConsumer.rawRequestRandomNumber.selector), "Revert");

    vm.expectEmit();
    emit RNGConsumer.FailedToRequestRandomNumber();

    cut.exposedRequestRandomNumber();
  }

  function test_requestRandomNumber_DoesNotcall_onReceiveRandomNumber_ifRequestToOracleFails() public {
    vm.mockCallRevert(address(cut), abi.encodeWithSelector(RNGConsumer.rawRequestRandomNumber.selector), "Revert");

    cut.exposedRequestRandomNumber();

    assertEq(cut.randomNumberReceived(), 0); // 0 is the default value. The random number received will always be different.
  }

  function test_requestRandomNumber_emitsEvent() public {
    uint256 expectedRequestId = VRF_V2_WRAPPER_MOCK.lastRequestId() + 1;

    vm.expectEmit();
    emit RNGConsumer.RandomNumberRequested(expectedRequestId);

    cut.exposedRequestRandomNumber();
  }

  function test_fulfillRandomWords_calls_onReceiveRandomNumber() public {
    vm.expectEmit();
    emit RNGConsumerHarness.OnReceiveRandomNumberCalled();

    cut.exposedRequestRandomNumber();
  }

  function test_fulfillRandomWords_doesNotcall_onFailToGenerateRandomNumber_IfSuccess() public {
    cut.exposedRequestRandomNumber();

    assertFalse(cut.requestHasFailed());
  }

  function test_fulfillRandomWords_emitsEvent() public {
    uint256[] memory randomWords = new uint256[](2);
    for (uint256 i = 0; i < randomWords.length; i++) {
      randomWords[i] = i; // making it fail with overflow, as it will multiply UINT256_MAX two times
    }

    uint256 expectedRandomNumber = Math.multiplyBetween(VRF_V2_WRAPPER_MOCK.randomWordsToReceive());
    uint256 expectedRequestId = VRF_V2_WRAPPER_MOCK.lastRequestId() + 1;

    vm.expectEmit();
    emit RNGConsumer.RandomNumberReceived(expectedRequestId, expectedRandomNumber);

    cut.exposedRequestRandomNumber();
  }

  function test_fulfillRandomWords_calls_onFailToGenerateRandomNumber_IfTheMultiplicationFails() public {
    uint256[] memory randomWords = new uint256[](2);
    for (uint256 i = 0; i < randomWords.length; i++) {
      randomWords[i] = UINT256_MAX; // making it fail with overflow, as it will multiply UINT256_MAX two times
    }

    cut.exposedFulfillRandomWords(0, randomWords);

    assertTrue(cut.requestHasFailed(), "Request should fail and call `_onFailToGenerateRandomNumber`");
  }

  function test_fulfillRandomWords_emitsEventIfTheMultiplicationFails() public {
    uint256[] memory randomWords = new uint256[](2);
    for (uint256 i = 0; i < randomWords.length; i++) {
      randomWords[i] = UINT256_MAX; // making it fail with overflow, as it will multiply UINT256_MAX two times
    }

    vm.expectEmit();
    emit RNGConsumer.FailedToGenerateRandomNumber(0, randomWords);

    cut.exposedFulfillRandomWords(0, randomWords);
  }
}
