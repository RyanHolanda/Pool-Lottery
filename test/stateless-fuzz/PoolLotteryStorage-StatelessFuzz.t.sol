// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";

contract PoolLotteryStorageStatelessFuzzTest is BaseTest {
  IPoolLotteryStorage public poolStorage;

  function onlyOwnerTest(address owner, address notOwner, bytes memory method) public {
    assumeNotZeroAddress(owner);
    vm.assume(owner != notOwner);

    PoolLotteryStorage _poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: owner
    });

    vm.startPrank(notOwner);
    (bool success, bytes memory data) = address(_poolStorage).call(method); // solhint-disable-line avoid-low-level-calls

    assertEq(success, false);
    assertEq(data, abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));

    vm.stopPrank();
  }

  function setUp() public override {
    poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    super.setUp();
  }

  function testGetTicketPrice(uint256 ticketPrice) public {
    IPoolLotteryStorage _poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: ticketPrice,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    (uint256 _ticketPrice, uint8 decimals) = _poolStorage.getTicketPrice();

    assert(_ticketPrice == ticketPrice);
    assert(decimals == MOCK_ERC_20.decimals());
  }

  function testGetLotteryEndDate(uint256 lotteryDuration) public {
    lotteryDuration = bound(lotteryDuration, 0, UINT256_MAX - block.timestamp); // solhint-disable-line not-rely-on-time

    IPoolLotteryStorage _poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: lotteryDuration,
      owner: address(this)
    });
    assert(_poolStorage.getLotteryEndDate() == (block.timestamp + lotteryDuration)); // solhint-disable-line not-rely-on-time
  }

  function testGetLotteryToken(IERC20 token) public {
    IPoolLotteryStorage _poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: token,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });
    assert(_poolStorage.getLotteryToken() == token);
  }

  function testAddPlayer(address player) public {
    vm.assume(player != address(0));
    poolStorage.addPlayer(player);

    assertEq(poolStorage.containsPlayer(player), true);
  }

  function testSetWinnerRevertsIfWinnerIsNotInPlayersList(address winner) public {
    vm.expectRevert(IPoolLotteryStorage.IPoolLotteryStorage__NotAPlayer.selector);
    poolStorage.setWinner(winner);
  }

  function testWithdrawRevertsIfNotInThePlayersList(address user) public {
    assumeNotZeroAddress(user);

    vm.expectRevert(IPoolLotteryStorage.IPoolLotteryStorage__NotAPlayer.selector);
    poolStorage.withdraw(200, user);
  }

  function test_Withdraw_RevertsIfWinnerIsChosenAndWithdrawIsNotToWinner(address winner, address notWinner) public {
    vm.assume(winner != notWinner);
    assumeNotZeroAddress(winner);
    assumeNotZeroAddress(notWinner);

    poolStorage.addPlayer(winner);
    poolStorage.addPlayer(notWinner);
    poolStorage.setWinner(winner);

    vm.expectRevert(abi.encodeWithSelector(IPoolLotteryStorage.IPoolLotteryStorage__WithdrawOnlyToWinner.selector, winner));
    poolStorage.withdraw(TICKET_PRICE, notWinner);
  }

  function test_Withdraw_DontRevertIfWinnerIsChosenAndWithdrawIsToWinner(address winner) public {
    vm.assume(winner != address(poolStorage));
    mintMockERC20(address(poolStorage), TICKET_PRICE);

    assumeNotZeroAddress(winner);

    poolStorage.addPlayer(winner);
    poolStorage.setWinner(winner);

    uint256 winnerBalanceBeforeWithdraw = poolStorage.getLotteryToken().balanceOf(winner);

    poolStorage.withdraw(TICKET_PRICE, winner);
    assertEq(poolStorage.getLotteryToken().balanceOf(winner), winnerBalanceBeforeWithdraw + TICKET_PRICE);
  }

  function testRemovePlayerRevertsIfNotInThePlayersList(address user) public {
    assumeNotZeroAddress(user);

    vm.expectRevert(IPoolLotteryStorage.IPoolLotteryStorage__NotAPlayer.selector);
    poolStorage.removePlayer(address(user));
  }

  function testAddPlayerRevertsIfAlreadyInThePlayersList(address player) public {
    assumeNotZeroAddress(player);
    poolStorage.addPlayer(player);

    vm.expectRevert(IPoolLotteryStorage.IPoolLotteryStorage__AlreadyAPlayer.selector);
    poolStorage.addPlayer(player);
  }

  function testSetWinner(address winner) public {
    poolStorage.addPlayer(winner);

    poolStorage.setWinner(winner);

    assertEq(poolStorage.getWinner(), winner);
  }

  function test_SetWinner_RevertsIfWinnerAlreadySet(address winner_A, address winner_B) public {
    vm.assume(winner_A != winner_B);

    assumeNotZeroAddress(winner_A);
    assumeNotZeroAddress(winner_B);

    poolStorage.addPlayer(winner_A);
    poolStorage.addPlayer(winner_B);

    poolStorage.setWinner(winner_A);

    vm.expectRevert(IPoolLotteryStorage.IPoolLotteryStorage__WinnerAlreadySet.selector);
    poolStorage.setWinner(winner_B);
  }

  function testOnlyOwnerCanPerformWithdraw(address owner, address notOwner) public {
    onlyOwnerTest(owner, notOwner, abi.encodeWithSelector(PoolLotteryStorage.withdraw.selector, ""));
  }

  function testOnlyOwnerCanPerformRemovePlayer(address owner, address notOwner) public {
    onlyOwnerTest(owner, notOwner, abi.encodeWithSelector(PoolLotteryStorage.removePlayer.selector, ""));
  }

  function testOnlyOwnerCanPerformAddPlayer(address owner, address notOwner) public {
    onlyOwnerTest(owner, notOwner, abi.encodeWithSelector(PoolLotteryStorage.addPlayer.selector, ""));
  }

  function testOnlyOwnerCanPerformSetStatus(address owner, address notOwner) public {
    onlyOwnerTest(owner, notOwner, abi.encodeWithSelector(PoolLotteryStorage.setStatus.selector, LotteryStatus.CLOSED));
  }

  function testOnlyOwnerCanPerformSetWinner(address owner, address notOwner) public {
    onlyOwnerTest(owner, notOwner, abi.encodeWithSelector(PoolLotteryStorage.setWinner.selector, ""));
  }
}
