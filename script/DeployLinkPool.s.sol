// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "@forge/Script.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {NetworkConfigHelper, NetworkConfig} from "script/Helpers/NetworkConfigHelper.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract DeployLinkPool is Script {
  function run() public returns (ILinkPool) {
    NetworkConfigHelper networkConfigHelper = new NetworkConfigHelper();
    NetworkConfig memory networkConfig = networkConfigHelper.getCurrentNetworkConfig();

    address poolLotteryManager = DevOpsTools.get_most_recent_deployment("PoolLotteryManager", networkConfig.chainId);

    vm.startBroadcast();
    ILinkPool linkPool = new LinkPool({linkToken: address(networkConfig.linkToken), owner: poolLotteryManager});
    vm.stopBroadcast();

    return linkPool;
  }
}
