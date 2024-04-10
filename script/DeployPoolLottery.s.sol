// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "@forge/Script.sol";
import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {IPoolLotteryStorage} from "src/interfaces/IPoolLotteryStorage.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {NetworkConfigHelper, NetworkConfig} from "script/Helpers/NetworkConfigHelper.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolLotteryManager} from "src/interfaces/IPoolLotteryManager.sol";

contract DeployPoolLottery is Script {
  function run() public returns (IPoolLottery, IPoolLotteryStorage) {
    NetworkConfigHelper networkConfigHelper = new NetworkConfigHelper();
    NetworkConfig memory networkConfig = networkConfigHelper.getCurrentNetworkConfig();

    uint32 vrfCallbackGasLimit = networkConfig.vrfCallbackGasLimit;
    uint16 vrfMinimumRequestConfirmations = networkConfig.vrfMinimumRequestConfirmations;
    address linkTokenAddress = networkConfig.linkToken;
    address vrfV2Wrapper = networkConfig.vrfV2Wrapper;
    address linkPool = DevOpsTools.get_most_recent_deployment("LinkPool", networkConfig.chainId);
    address poolLotteryManager = DevOpsTools.get_most_recent_deployment("PoolLotteryManager", networkConfig.chainId);

    vm.startBroadcast();
    PoolLotteryStorage poolStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: 1_0000,
      lotteryToken: IERC20(0x29f2D40B0605204364af54EC677bD022dA425d03), // WBTC, faucet: https://staging.aave.com/faucet/
      lotteryDuration: 20 minutes,
      owner: msg.sender
    });

    PoolLottery poolLottery = new PoolLottery({
      vrfCallbackGasLimit: vrfCallbackGasLimit,
      vrfMinimumRequestConfirmations: vrfMinimumRequestConfirmations,
      linkTokenAddress: linkTokenAddress,
      vrfV2Wrapper: vrfV2Wrapper,
      linkPool: linkPool,
      poolStorage: address(poolStorage),
      poolLotteryManager: poolLotteryManager
    });

    poolStorage.transferOwnership(address(poolLottery));
    IPoolLotteryManager(poolLotteryManager).setNewLottery(address(poolLottery));

    vm.stopBroadcast();

    return (poolLottery, poolStorage);
  }
}
