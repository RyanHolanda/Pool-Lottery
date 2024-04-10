// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract PoolLotteryStorageTest is BaseTest {
  using Strings for uint256;

  IPoolLotteryStorage public poolStorage;
  IERC20 public lotteryToken;

  function setUp() public override {
    lotteryToken = MOCK_ERC_20;

    poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: lotteryToken,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    vm.startPrank(USER);
    lotteryToken.approve(address(this), UINT256_MAX);
    vm.stopPrank();

    super.setUp();
  }

  function testWithdraw() public {
    poolStorage.addPlayer(USER);

    uint256 userBalanceBeforeTransfer = lotteryToken.balanceOf(USER);

    lotteryToken.transferFrom(USER, address(poolStorage), TICKET_PRICE);

    assertEq(lotteryToken.balanceOf(address(poolStorage)), TICKET_PRICE, "Tokens wasn't transferred to PoolLotteryStorage");

    assertEq(
      lotteryToken.balanceOf(address(USER)),
      userBalanceBeforeTransfer - TICKET_PRICE,
      "Tokens wasn't transferred from user"
    );

    poolStorage.withdraw(TICKET_PRICE, USER);

    assertEq(lotteryToken.balanceOf(address(poolStorage)), 0);
    assertEq(lotteryToken.balanceOf(USER), userBalanceBeforeTransfer);
  }

  function testRemovePlayer() public {
    poolStorage.addPlayer(address(1));
    poolStorage.addPlayer(address(2));
    poolStorage.addPlayer(address(3));

    assertEq(poolStorage.containsPlayer(address(2)), true, "Player 2 wasn't added");

    poolStorage.removePlayer(address(2));

    assertEq(poolStorage.containsPlayer(address(2)), false);
  }

  function testSetStatus() public {
    poolStorage.setStatus(LotteryStatus.FINISHED);

    assert(poolStorage.getStatus() == LotteryStatus.FINISHED);
  }

  function testGetPlayers() public {
    address[3] memory playersToBeAdded = [address(1), address(2), address(3)];

    poolStorage.addPlayer(playersToBeAdded[0]);
    poolStorage.addPlayer(playersToBeAdded[1]);
    poolStorage.addPlayer(playersToBeAdded[2]);

    address[] memory players = poolStorage.getPlayers();

    for (uint256 i = 0; i < players.length; i++) {
      assertEq(players[i], playersToBeAdded[i]);
    }
  }

  function testContainsPlayer__False() public {
    address[3] memory playersToBeAdded = [address(1), address(2), address(3)];

    poolStorage.addPlayer(playersToBeAdded[0]);
    poolStorage.addPlayer(playersToBeAdded[1]);
    poolStorage.addPlayer(playersToBeAdded[2]);

    assertEq(poolStorage.containsPlayer(address(125)), false);
  }

  function testContainsPlayer__True() public {
    address[3] memory playersToBeAdded = [address(1), address(2), address(3)];

    poolStorage.addPlayer(playersToBeAdded[0]);
    poolStorage.addPlayer(playersToBeAdded[1]);
    poolStorage.addPlayer(playersToBeAdded[2]);

    assertEq(poolStorage.containsPlayer(playersToBeAdded[1]), true);
  }

  function testStatusStartAsOpen() public view {
    assert(poolStorage.getStatus() == LotteryStatus.OPEN);
  }
}
