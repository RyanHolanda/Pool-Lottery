// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "@forge/Script.sol";
import {PoolLottery} from "src/contracts/PoolLottery.sol";
import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Draft script to deploy a PoolLottery.
/// !🚫 This should never be used in Production to deploy a PoolLottery.
/// Only for testing purposes.
contract DraftDeployPoolLotterySepolia is Script {
  function run() public returns (IPoolLottery) {
    address usdtTokenAddress = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    uint256 tokenDecimals = 6;

    vm.startBroadcast();
    IPoolLottery poolLottery = new PoolLottery({
      ticketPriceInTokenAmountWithDecimals: 1 * (10 ** tokenDecimals),
      lotteryToken: IERC20(usdtTokenAddress)
    });
    vm.stopBroadcast();

    return poolLottery;
  }
}
