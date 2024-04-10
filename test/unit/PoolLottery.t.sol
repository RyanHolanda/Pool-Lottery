//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {RNGConsumer} from "src/contracts/RNGConsumer.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {Math} from "src/libraries/Math.sol";
import {console} from "@forge/Test.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {SafeLotteryStatus} from "src/libraries/SafeLotteryStatus.sol";

contract PoolLotteryTest is BaseTest {
  using SafeLotteryStatus for LotteryStatus;
  using Strings for uint256;

  IPoolLottery public cut;
  PoolLotteryStorage public poolStorage;

  modifier joinedPool() {
    vm.startPrank(USER);
    vm.deal(USER, 100 ether);
    MOCK_ERC_20.approve(address(cut), 1000 ether);
    cut.enterPool();
    vm.stopPrank();
    _;
  }

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

    poolStorage = new PoolLotteryStorage({
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
      address(poolStorage),
      address(this)
    );

    poolStorage.transferOwnership(address(cut));
    LINK_POOL.addSpender(address(cut));
    MOCK_ERC_20.approve(address(cut), UINT256_MAX);
  }

  function testEnterPoolRevertsIfUserHasAlreadyJoined() public joinedPool userAsSender {
    vm.expectRevert(IPoolLottery.IPoolLottery__AlreadyJoined.selector);
    cut.enterPool();
  }

  function testEnterPoolEmitsTicketBoughtEvent() public userAsSender {
    approveAndMintMockERC20(address(cut), USER);

    vm.expectEmit(true, true, false, false);
    emit IPoolLottery.IPoolLottery__TicketBought(USER, TICKET_PRICE);
    cut.enterPool();

    vm.stopPrank();
  }

  function testExitPoolEmitsEvent() public joinedPool userAsSender {
    vm.expectEmit(true, true, true, true);
    emit IPoolLottery.IPoolLottery__Exited(USER, TICKET_PRICE);
    cut.exitPool();
  }

  function testUserCannotEnterPoolIfStatusIsNotOpen() public poolWithUsers {
    vm.startPrank(address(cut));
    poolStorage.setStatus(LotteryStatus.CLOSED);
    vm.stopPrank();

    vm.expectRevert(IPoolLottery.IPoolLottery__NotOpen.selector);
    cut.enterPool();
  }

  function testUserCannoEnterLotteryIfEndDateWasReached__SameMoment() public {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate);

    vm.expectRevert(IPoolLottery.IPoolLottery__EndDateReached.selector);
    cut.enterPool();
  }

  function testUserCannoEnterLotteryIfEndDateWasReached__AfterSomeTime() public {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 100 hours);

    vm.expectRevert(IPoolLottery.IPoolLottery__EndDateReached.selector);
    cut.enterPool();
  }

  function testUserCannotExitPoolIfStatusIsNotOpen() public poolWithUsers {
    vm.startPrank(USER);

    MOCK_ERC_20.approve(address(cut), UINT256_MAX);
    cut.enterPool();

    vm.stopPrank();

    vm.startPrank(address(cut));
    poolStorage.setStatus(LotteryStatus.CLOSED);
    vm.stopPrank();

    vm.startPrank(USER);

    vm.expectRevert(IPoolLottery.IPoolLottery__NotOpen.selector);
    cut.exitPool();

    vm.stopPrank();
  }

  function testUserCannoExitLotteryIfEndDateWasReached__SameMoment() public userAsSender {
    MOCK_ERC_20.approve(address(cut), UINT256_MAX);
    cut.enterPool();

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate);

    vm.expectRevert(IPoolLottery.IPoolLottery__EndDateReached.selector);
    cut.exitPool();
  }

  function testUserCannoExitLotteryIfEndDateWasReached__AfterSomeTime() public userAsSender {
    MOCK_ERC_20.approve(address(cut), UINT256_MAX);
    cut.enterPool();

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    vm.expectRevert(IPoolLottery.IPoolLottery__EndDateReached.selector);
    cut.exitPool();
  }

  function testChooseWinnerRevertsIfStatusIsNotOpen() public poolWithUsers {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 1 hours);
    cut.chooseWinner(); // Changing the lottery status

    vm.expectRevert(IPoolLottery.IPoolLottery__NotOpen.selector);
    cut.chooseWinner();
  }

  function testChooseWinnerRevertsIfPlayersListIsEmpty() public {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 1 hours);

    vm.expectRevert(IPoolLottery.IPoolLottery__NotEnoughPlayers.selector);
    cut.chooseWinner();
  }

  function testChooseWinnerRevertsIfEndDateWasNotReached() public poolWithUsers {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate - 1 hours);

    vm.expectRevert(IPoolLottery.IPoolLottery__EndDateNotReached.selector);
    cut.chooseWinner();
  }

  function test_chooseWinner_requestsRandomNumber() public poolWithUsers {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    vm.expectCall(address(cut), abi.encodeWithSelector(RNGConsumer.rawRequestRandomNumber.selector));
    cut.chooseWinner();
  }

  function test_transferFundsToWinner_revertsIfStatusIsNotFinished() public poolWithUsers {
    assert(poolStorage.getStatus() != LotteryStatus.FINISHED);

    vm.expectRevert(IPoolLottery.IPoolLottery__NotFinished.selector);
    cut.transferFundsToWinner();
  }

  function test_transferFundsToWinner_revertsIfWinnerAddressIsZero() public poolWithUsers {
    assert(poolStorage.getWinner() == address(0));

    vm.startPrank(address(cut));
    poolStorage.setStatus(LotteryStatus.FINISHED);
    vm.stopPrank();

    vm.expectRevert(IPoolLottery.IPoolLottery__InvalidWinner.selector);
    cut.transferFundsToWinner();
  }

  function test_transferFundsToWinner_SendFundsToTheWinner() public poolWithUsers {
    uint256 poolBalanceBeforeTransfer = poolStorage.getLotteryToken().balanceOf(address(poolStorage));
    uint256 userBalanceBeforeTransfer = poolStorage.getLotteryToken().balanceOf(USER);

    vm.startPrank(address(cut));
    poolStorage.addPlayer(USER);
    poolStorage.setWinner(address(USER));
    poolStorage.setStatus(LotteryStatus.FINISHED);
    vm.stopPrank();

    cut.transferFundsToWinner();

    uint256 userBalanceAfterTransfer = poolStorage.getLotteryToken().balanceOf(USER);
    uint256 poolBalanceAfterTransfer = poolStorage.getLotteryToken().balanceOf(address(poolStorage));

    assertEq(userBalanceAfterTransfer, poolBalanceBeforeTransfer + userBalanceBeforeTransfer);
    assertEq(poolBalanceAfterTransfer, 0, "All funds must be transferred to the winner");
  }

  function test_onReceiveRandomNumber_setRightPlayerWhenRandomNumberIsLessThanNumberOfPlayers() public poolWithUsers {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);
    address[] memory players = poolStorage.getPlayers();

    uint256[] memory randomWords = new uint256[](2);
    randomWords[0] = 2;
    randomWords[1] = 3;

    uint256 expectedRandomNumber = Math.multiplyBetween(randomWords);
    assertLt(expectedRandomNumber, players.length, "The random number should be less than the number of players");

    VRF_V2_WRAPPER_MOCK.overrideRandomWords(randomWords);
    cut.chooseWinner();

    assertEq(poolStorage.getWinner(), players[expectedRandomNumber]);
  }

  function test_onReceiveRandomNumber_performModulusOperationToChooseWinnerIfRandomNumberIsGreaterThanNumberOfPlayers()
    public
    poolWithUsers
  {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);
    address[] memory players = poolStorage.getPlayers();

    uint256[] memory randomWords = new uint256[](2);
    randomWords[0] = 78324113;
    randomWords[1] = 29;

    uint256 expectedRandomNumber = Math.multiplyBetween(randomWords);
    uint256 expectedPlayerIndex = expectedRandomNumber % players.length;

    assertGt(expectedRandomNumber, players.length, "The random number should be greater than the number of players");

    VRF_V2_WRAPPER_MOCK.overrideRandomWords(randomWords);
    cut.chooseWinner();

    assertEq(poolStorage.getWinner(), players[expectedPlayerIndex]);
  }

  function test_onReceiveRandomNumber_CanSelectLastPlayerAsWinner() public {
    uint256 usersCount = 10;
    uint256 numberMultipliedToAchieveLastUser = 78324113;

    for (uint256 i = 0; i < usersCount; i++) {
      address user = makeAddr(i.toString());
      vm.startPrank(user);
      approveAndMintMockERC20(address(cut), user);
      cut.enterPool();
      vm.stopPrank();
    }

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    address[] memory players = poolStorage.getPlayers();
    uint256[] memory randomWords = new uint256[](2);
    randomWords[0] = numberMultipliedToAchieveLastUser;
    randomWords[1] = numberMultipliedToAchieveLastUser;

    uint256 lastPlayerIndex = players.length - 1;

    VRF_V2_WRAPPER_MOCK.overrideRandomWords(randomWords);
    cut.chooseWinner();

    assertEq(poolStorage.getWinner(), players[lastPlayerIndex]);
  }

  function test_onReceiveRandomNumber_CanSelectFirstPlayerAsWinner() public {
    uint256 usersCount = 10;
    uint256 numberMultipliedToAchieveFirstUser = 500;

    for (uint256 i = 0; i < usersCount; i++) {
      address user = makeAddr(i.toString());
      vm.startPrank(user);
      approveAndMintMockERC20(address(cut), user);
      cut.enterPool();
      vm.stopPrank();
    }

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    address[] memory players = poolStorage.getPlayers();
    uint256[] memory randomWords = new uint256[](2);
    randomWords[0] = numberMultipliedToAchieveFirstUser;
    randomWords[1] = numberMultipliedToAchieveFirstUser;

    VRF_V2_WRAPPER_MOCK.overrideRandomWords(randomWords);
    cut.chooseWinner();

    assertEq(poolStorage.getWinner(), players[0]);
  }

  function test_onReceiveRandomNumber_setStatusToFinished() public poolWithUsers {
    assert(poolStorage.getStatus() != LotteryStatus.FINISHED);

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    cut.chooseWinner();

    assert(poolStorage.getStatus() == LotteryStatus.FINISHED);
  }

  function test_onReceiveRandomNumber_emitsEvent() public poolWithUsers {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    address[] memory players = poolStorage.getPlayers();
    uint256[] memory randomWords = new uint256[](2);
    randomWords[0] = 2;
    randomWords[1] = 3;

    address expectedWinner = players[Math.multiplyBetween(randomWords)];
    VRF_V2_WRAPPER_MOCK.overrideRandomWords(randomWords);

    vm.expectEmit();
    emit IPoolLottery.IPoolLottery__WinnerChosen(expectedWinner);
    cut.chooseWinner();
  }

  function test_onReceiveRandomNumber_transferFundsToWinner() public poolWithUsers {
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);
    uint256 lotteryBalance = poolStorage.getLotteryToken().balanceOf(address(poolStorage));

    address[] memory players = poolStorage.getPlayers();
    uint256[] memory randomWords = new uint256[](2);
    randomWords[0] = 2;
    randomWords[1] = 3;

    address expectedWinner = players[Math.multiplyBetween(randomWords)];
    VRF_V2_WRAPPER_MOCK.overrideRandomWords(randomWords);

    vm.expectCall(
      address(poolStorage),
      abi.encodeWithSelector(PoolLotteryStorage.withdraw.selector, lotteryBalance, expectedWinner)
    );
    cut.chooseWinner();
  }

  function test_onFailToGenerateRandomNumber_setStatusToFailed() public poolWithUsers {
    vm.mockCallRevert(address(LINK_TOKEN), abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector), "Revert");

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    cut.chooseWinner();

    assertTrue(poolStorage.getStatus().isFailed());
  }

  function test_onFailToGenerateRandomNumber_emitsEvent() public poolWithUsers {
    vm.mockCallRevert(address(LINK_TOKEN), abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector), "Revert");

    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();
    vm.warp(lotteryEndDate + 2 hours);

    vm.expectEmit();
    emit IPoolLottery.IPoolLottery__Failed();
    cut.chooseWinner();
  }
}
