// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PoolLotteryStatelessFuzzTest is BaseTest {
  using Strings for uint256;

  IPoolLottery public cut;
  PoolLotteryStorage public poolStorage;
  uint256 public expectedPlayersCount = 0;
  uint256 public expectedPoolBalance = 0;

  modifier onlyValidAddress(address addressToVerify) {
    vm.assume(addressToVerify != address(0));
    vm.assume(addressToVerify != address(cut));
    vm.assume(addressToVerify != address(poolStorage));
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
    MOCK_ERC_20.approve(address(cut), 1000 ether);
  }

  function test_transferStorageOwnership_revertsIfTheSenderIsNotTheOwner(address newOwner) public {
    vm.startPrank(newOwner);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, newOwner));
    cut.transferStorageOwnership(newOwner);

    vm.stopPrank();
  }

  function test_transferStorageOwnership_success(address newOwner) public {
    assumeNotZeroAddress(newOwner);

    cut.transferStorageOwnership(newOwner);

    assertEq(poolStorage.owner(), newOwner);
  }

  function testRightPlayerIsAddedToThePool(address user) public onlyValidAddress(user) {
    vm.startPrank(user);

    approveAndMintMockERC20(address(cut), user);
    cut.enterPool();

    vm.stopPrank();

    address[] memory players = poolStorage.getPlayers();
    assertEq(players[expectedPlayersCount], user);

    ++expectedPlayersCount;
  }

  function testTransferFromIsCorrectWhenUserJoinsThePool(address user) public onlyValidAddress(user) {
    vm.startPrank(user);

    approveAndMintMockERC20(address(cut), user);
    vm.expectEmit(true, true, true, true);
    emit IERC20.Transfer(user, address(poolStorage), TICKET_PRICE);
    cut.enterPool();

    vm.stopPrank();
  }

  function testEnterPoolSendTicketTokenToPool(address user) public onlyValidAddress(user) {
    vm.startPrank(user);

    approveAndMintMockERC20(address(cut), user);
    cut.enterPool();

    vm.stopPrank();

    expectedPoolBalance += TICKET_PRICE;

    IERC20 lotteryToken = poolStorage.getLotteryToken();
    assertEq(lotteryToken.balanceOf(address(poolStorage)), expectedPoolBalance);
    assertEq(lotteryToken.balanceOf(address(cut)), 0, "The pool should never handle the ticket token, but it did");
  }

  function testExitPoolRevertsIfNotJoined(address user) public onlyValidAddress(user) {
    vm.expectRevert(IPoolLottery.IPoolLottery__NotJoined.selector);
    vm.startPrank(user);
    cut.exitPool();
    vm.stopPrank();
  }

  function testExitPoolRemovesThePlayerFromThePool(address user) public onlyValidAddress(user) {
    vm.startPrank(user);
    approveAndMintMockERC20(address(cut), user);
    cut.enterPool();
    vm.stopPrank();

    // solhint-disable-next-line
    require(poolStorage.getPlayers().length > 0, "User did not join the pool");

    vm.startPrank(user);
    cut.exitPool();
    vm.stopPrank();

    assertEq(poolStorage.getPlayers().length, 0);
  }

  function testExitPoolSendUserTicketPriceBack(address user) public onlyValidAddress(user) {
    vm.startPrank(user);
    approveAndMintMockERC20(address(cut), user, TICKET_PRICE);
    uint256 userBalanceBeforeEnterPool = MOCK_ERC_20.balanceOf(user);
    cut.enterPool();

    assertEq(MOCK_ERC_20.balanceOf(user), userBalanceBeforeEnterPool - TICKET_PRICE, "User did not send ticket price to pool");

    cut.exitPool();
    vm.stopPrank();

    assertEq(MOCK_ERC_20.balanceOf(user), userBalanceBeforeEnterPool);
  }

  function test_exitPool_bypassChecksIfStatusIsFailed(address user) public {
    // When the user is in the pool, and the lottery status is Failed,
    // the user should be able to exit the pool whenever he wants to.
    assumeNotZeroAddress(user);
    uint256 lotteryEndDate = poolStorage.getLotteryEndDate();

    vm.startPrank(user);
    approveAndMintMockERC20(address(cut), user, TICKET_PRICE);
    cut.enterPool();
    vm.stopPrank();

    assertEq(poolStorage.getPlayers().length, 1, "User should enter in the pool");

    vm.startPrank(address(cut));
    poolStorage.setStatus(LotteryStatus.FAILED);
    vm.stopPrank();

    vm.warp(lotteryEndDate + 2 hours);

    vm.startPrank(user);
    cut.exitPool();
    vm.stopPrank();

    assertEq(poolStorage.getPlayers().length, 0, "User should be removed from the pool");
  }

  function test_exitPool_RevertIfUserTryToExitWhenStatusIsFailedButUserIsNotInPool(address user) public {
    assumeNotZeroAddress(user);

    vm.startPrank(address(cut));
    poolStorage.setStatus(LotteryStatus.FAILED);
    vm.stopPrank();

    vm.startPrank(user);
    vm.expectRevert(IPoolLottery.IPoolLottery__NotJoined.selector);
    cut.exitPool();
    vm.stopPrank();
  }

  function testEnterPoolRevertsIfBalanceIsNotEnoughToPayForTheTicket(address user) public {
    vm.assume(user != USER); // "USER" will have balance to pay for the ticket
    vm.startPrank(user);

    vm.expectRevert(IPoolLottery.IPoolLottery__NotEnoughBalance.selector);
    cut.enterPool();

    vm.stopPrank();
  }
}
