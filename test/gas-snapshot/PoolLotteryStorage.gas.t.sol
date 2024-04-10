// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {GasSnapshot} from "@forge-gas-snapshot/src/GasSnapshot.sol";
import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {LotteryStatus} from "src/types/LotteryStatus.sol";

contract PoolLotteryStorageGasTest is BaseTest, GasSnapshot {
  IPoolLotteryStorage public cut;

  function setUp() public override {
    cut = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });
  }

  function testGas_withdraw() public {
    setCheckMode(true);

    cut.addPlayer(USER);
    mintMockERC20(address(cut), TICKET_PRICE);

    snapStart("PoolLotteryStorage_withdraw");
    cut.withdraw({amount: TICKET_PRICE, to: USER});
    snapEnd();
  }

  function testGas_removePlayer() public {
    setCheckMode(true);

    cut.addPlayer(USER);

    snapStart("PoolLotteryStorage_removePlayer");
    cut.removePlayer(USER);
    snapEnd();
  }

  function testGas_addPlayer() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_addPlayer");
    cut.addPlayer(USER);
    snapEnd();
  }

  function testGas_setStatus() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_setStatus");
    cut.setStatus(LotteryStatus.CLOSED);
    snapEnd();
  }

  function testGas_setWinner() public {
    setCheckMode(false);

    cut.addPlayer(USER);

    snapStart("PoolLotteryStorage_setWinner");
    cut.setWinner(USER);
    snapEnd();
  }

  function testGas_getStatus() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_getStatus");
    cut.getStatus();
    snapEnd();
  }

  function testGas_getPlayers() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_getPlayers");
    cut.getPlayers();
    snapEnd();
  }

  function testGas_containsPlayer() public {
    setCheckMode(true);

    cut.addPlayer(USER);

    snapStart("PoolLotteryStorage_containsPlayer");
    cut.containsPlayer(USER);
    snapEnd();
  }

  function testGas_getWinner() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_getWinner");
    cut.getWinner();
    snapEnd();
  }

  function testGas_getTicketPrice() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_getTicketPrice");
    cut.getTicketPrice();
    snapEnd();
  }

  function testGas_getLotteryToken() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_getLotteryToken");
    cut.getLotteryToken();
    snapEnd();
  }

  function testGas_getLotteryEndDate() public {
    setCheckMode(true);

    snapStart("PoolLotteryStorage_getLotteryEndDate");
    cut.getLotteryEndDate();
    snapEnd();
  }
}
