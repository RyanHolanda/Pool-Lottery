// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

import {Script} from "@forge/Script.sol";
import {PoolLotteryManager} from "src/contracts/PoolLottery/PoolLotteryManager.sol";
import {IPoolLotteryManager} from "src/interfaces/IPoolLotteryManager.sol";
import {NetworkConfigHelper, NetworkConfig} from "script/Helpers/NetworkConfigHelper.s.sol";

contract DeployPoolLotteryManager is Script {
  function run() public returns (IPoolLotteryManager) {
    NetworkConfigHelper networkConfigHelper = new NetworkConfigHelper();
    NetworkConfig memory networkConfig = networkConfigHelper.getCurrentNetworkConfig();

    address linkPool = DevOpsTools.get_most_recent_deployment("LinkPool", networkConfig.chainId);

    vm.startBroadcast();
    PoolLotteryManager poolLotteryManager = new PoolLotteryManager(msg.sender, linkPool);
    vm.stopBroadcast();

    return poolLotteryManager;
  }
}
