// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {Math} from "src/libraries/Math.sol";
import {ILinkPool} from "src/interfaces/ILinkPool.sol";

/**
 * @title Oracle Implementation to generate random numbers.
 */
abstract contract RNGConsumer is VRFV2WrapperConsumerBase {
  using Math for uint256[];

  uint32 private constant NUM_RANDOM_WORDS = 20;

  uint32 private immutable i_callbackGasLimit;
  uint16 private immutable i_minimumRequestConfirmations;
  ILinkPool private immutable i_linkPool;

  event RandomNumberReceived(uint256 indexed requestId, uint256 indexed randomNumber);

  event RandomNumberRequested(uint256 indexed requestId);

  /// @notice emitted when our algorithm fails to generate a random number (but sucessfully received numbers from Oracle)
  event FailedToGenerateRandomNumber(uint256 indexed requestId, uint256[] indexed receivedNumbers);

  /// @notice emitted when the request to generate a random number fails. (Did not make the request to Oracle)
  event FailedToRequestRandomNumber();

  /// @notice thrown on try to request something from the oracle and the sender is not this contract
  error OnlyThisContractCanRequestFromOracle();

  /// @notice thrown when the transfer of LINK to this contract(for making chainlink requests) fails
  error FailedToReceiveLink();

  constructor(
    uint32 vrfCallbackGasLimit,
    uint16 vrfMinimumRequestConfirmations,
    address linkTokenAddress,
    address vrfV2Wrapper,
    address linkPool
  ) VRFV2WrapperConsumerBase(linkTokenAddress, vrfV2Wrapper) {
    i_linkPool = ILinkPool(linkPool);
    i_callbackGasLimit = vrfCallbackGasLimit;
    i_minimumRequestConfirmations = vrfMinimumRequestConfirmations;
  }
  /**
   * @notice requests a random number from Oracle
   * @dev this function is external to make it possible catch reverts from internal function calls.
   * @dev only use this function if you want to revert on failure. Otherwise, use the `requestRandomNumber`
   */
  function rawRequestRandomNumber() external returns (uint256 requestId) {
    if (msg.sender != address(this)) revert OnlyThisContractCanRequestFromOracle();

    bool success = LINK.transferFrom(
      address(i_linkPool),
      address(this),
      VRF_V2_WRAPPER.calculateRequestPrice(i_callbackGasLimit)
    );

    if (!success) revert FailedToReceiveLink();

    requestId = requestRandomness(i_callbackGasLimit, i_minimumRequestConfirmations, NUM_RANDOM_WORDS);
  }

  /**
   * @notice Called once a random number is successfully generated
   *
   * @dev be cautious with reverts here, as the revert will not revert the request.
   * It will only revert the function that called it (`fulfillRandomWords`).
   *
   * @dev In case of reverts, the `_onFailToGenerateRandomNumber` is not called.
   */
  function _onReceiveRandomNumber(uint256 randomNumber) internal virtual;

  /// @notice Called once fails to request or generate a random number
  function _onFailToGenerateRandomNumber() internal virtual;

  /// @notice requests a random number from Oracle
  function _requestRandomNumber() internal {
    try this.rawRequestRandomNumber() returns (uint256 requestId) {
      emit RandomNumberRequested(requestId);
    } catch {
      _onFailToGenerateRandomNumber();
      emit FailedToRequestRandomNumber();
    }
  }

  /**
   * @notice Called once a random number is received from Chainlink VRF.
   * @dev this should never be called directly. Only the VRF Coordinator can call it
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    try randomWords.multiplyBetween() returns (uint256 randomNumber) {
      emit RandomNumberReceived(requestId, randomNumber);
      _onReceiveRandomNumber(randomNumber);
    } catch {
      emit FailedToGenerateRandomNumber(requestId, randomWords);
      _onFailToGenerateRandomNumber();
    }
  }
}
