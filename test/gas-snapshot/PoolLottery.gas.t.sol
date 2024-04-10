// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {GasSnapshot} from "@forge-gas-snapshot/src/GasSnapshot.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PoolLotteryHarness} from "test/harnesses/PoolLotterryHarness.t.sol";

contract PoolLotteryGasTest is BaseTest, GasSnapshot {
  using Strings for uint256;

  IPoolLottery public cut;
  PoolLotteryStorage public lotteryStorage;

  modifier poolWithUsers() {
    for (uint256 i = 0; i < 10; i++) {
      address user = makeAddr(i.toString());
      vm.startPrank(user);
      approveAndMintMockERC20(address(cut), user);
      cut.enterPool();
      vm.stopPrank();
    }
    _;
  }

  function setUp() public override {
    super.setUp();

    lotteryStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    cut = new PoolLottery(
      VRF_CALLBACK_GAS_LIMIT,
      VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      address(LINK_TOKEN),
      address(VRF_V2_WRAPPER_MOCK),
      address(LINK_POOL),
      address(lotteryStorage),
      address(this)
    );
    lotteryStorage.transferOwnership(address(cut));

    vm.startPrank(USER);
    approveAndMintMockERC20(address(cut), USER);
    vm.stopPrank();
  }

  function testGas_enterPool() public userAsSender {
    setCheckMode(true);

    snapStart("PoolLottery_EnterPool");
    cut.enterPool();
    snapEnd();
  }

  function testGas_exitPool() public userAsSender {
    setCheckMode(true);

    cut.enterPool();

    snapStart("PoolLottery_ExitPool");
    cut.exitPool();
    snapEnd();
  }

  function testGas_chooseWinner() public poolWithUsers {
    setCheckMode(true);

    uint256 lotteryEndDate = lotteryStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours); // changing the status to make possible to choose winner

    snapStart("PoolLottery_ChooseWinner");
    cut.chooseWinner();
    snapEnd();
  }

  function testGas_TransferFundsToWinner() public {
    setCheckMode(true);

    vm.startPrank(address(cut));
    lotteryStorage.addPlayer(USER);
    lotteryStorage.setStatus(LotteryStatus.FINISHED);
    lotteryStorage.setWinner(USER);

    snapStart("PoolLottery_TransferFundsToWinner");
    cut.transferFundsToWinner();
    snapEnd();

    vm.stopPrank();
  }

  function testGas_onReceiveRandomNumber(uint8[VRF_NUM_WORDS_TO_REQUEST] memory randomNumbers) public {
    setCheckMode(true);

    PoolLotteryHarness poolLotteryHarness = new PoolLotteryHarness();

    uint256[] memory randomNumbersAsUint256 = new uint256[](randomNumbers.length);
    for (uint256 i = 0; i < randomNumbers.length; i++) {
      randomNumbersAsUint256[i] = uint256(randomNumbers[i] == 0 ? 1 : randomNumbers[i]);
    }

    poolLotteryHarness.enterPool();
    vm.startPrank(address(VRF_V2_WRAPPER_MOCK));

    snapStart("PoolLottery_onReceiveRandomNumber");
    poolLotteryHarness.exposed_onReceiveRandomNumber(634563564356462);
    snapEnd();

    vm.stopPrank();
  }

  function testGas_DeployPooLottery() public userAsSender {
    setCheckMode(true);

    snapStart("PoolLottery_Deploy");
    new PoolLottery(
      VRF_CALLBACK_GAS_LIMIT,
      VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      address(LINK_TOKEN),
      address(VRF_V2_WRAPPER_MOCK),
      address(LINK_POOL),
      address(lotteryStorage),
      address(this)
    );
    snapEnd();
  }
}
