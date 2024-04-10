// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {PoolLotteryManager} from "src/contracts/PoolLottery/PoolLotteryManager.sol";
import {IPoolLotteryManager} from "src/interfaces/IPoolLotteryManager.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {PoolLotteryStorage} from "src/contracts/PoolLottery/PoolLotteryStorage.sol";
import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";

contract PoolLotteryManagerTest is BaseTest {
  IPoolLotteryManager public poolLotteryManager;

  function setUp() public override {
    super.setUp();

    poolLotteryManager = new PoolLotteryManager(address(this), address(LINK_POOL));
    LinkPool(address(LINK_POOL)).transferOwnership(address(poolLotteryManager));
  }

  function test_setNewLottery_emitEvent() public {
    address newLottery = address(21);

    vm.expectEmit();
    emit IPoolLotteryManager.IPoolLotteryManager__NewLottery(newLottery);

    poolLotteryManager.setNewLottery(newLottery);
  }

  function test_upgradeCurrentLottery_TransferStorageOwnership() public {
    PoolLotteryStorage poolLotteryStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    PoolLottery oldImpl = new PoolLottery({
      vrfCallbackGasLimit: VRF_CALLBACK_GAS_LIMIT,
      vrfMinimumRequestConfirmations: VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      linkTokenAddress: address(LINK_TOKEN),
      vrfV2Wrapper: address(VRF_V2_WRAPPER_MOCK),
      linkPool: address(LINK_POOL),
      poolStorage: address(poolLotteryStorage),
      poolLotteryManager: address(poolLotteryManager)
    });

    poolLotteryStorage.transferOwnership(address(oldImpl));
    poolLotteryManager.setNewLottery(address(oldImpl));

    PoolLottery newImpl = new PoolLottery({
      vrfCallbackGasLimit: VRF_CALLBACK_GAS_LIMIT,
      vrfMinimumRequestConfirmations: VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      linkTokenAddress: address(LINK_TOKEN),
      vrfV2Wrapper: address(VRF_V2_WRAPPER_MOCK),
      linkPool: address(LINK_POOL),
      poolStorage: address(poolLotteryStorage),
      poolLotteryManager: address(poolLotteryManager)
    });

    vm.expectCall(address(oldImpl), abi.encodeWithSelector(IPoolLottery.transferStorageOwnership.selector, newImpl));
    poolLotteryManager.upgradeCurrentLottery(address(newImpl));
  }

  function test_upgradeCurrentLottery_set_currentLottery() public {
    PoolLotteryStorage poolLotteryStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    PoolLottery poolLottery = new PoolLottery({
      vrfCallbackGasLimit: VRF_CALLBACK_GAS_LIMIT,
      vrfMinimumRequestConfirmations: VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      linkTokenAddress: address(LINK_TOKEN),
      vrfV2Wrapper: address(VRF_V2_WRAPPER_MOCK),
      linkPool: address(LINK_POOL),
      poolStorage: address(poolLotteryStorage),
      poolLotteryManager: address(poolLotteryManager)
    });

    poolLotteryStorage.transferOwnership(address(poolLottery));
    poolLotteryManager.setNewLottery(address(poolLottery));

    address newLottery = address(21);
    poolLotteryManager.upgradeCurrentLottery(newLottery);

    assertEq(address(poolLotteryManager.getCurrentLottery()), newLottery);
  }

  function test_upgradeCurrentLottery_emitEvent() public {
    PoolLotteryStorage poolLotteryStorage = new PoolLotteryStorage({
      ticketPriceInTokenAmountWithDecimals: TICKET_PRICE,
      lotteryToken: MOCK_ERC_20,
      lotteryDuration: LOTTERY_DURATION,
      owner: address(this)
    });

    PoolLottery poolLottery = new PoolLottery({
      vrfCallbackGasLimit: VRF_CALLBACK_GAS_LIMIT,
      vrfMinimumRequestConfirmations: VRF_MINIMUM_REQUEST_CONFIRMATIONS,
      linkTokenAddress: address(LINK_TOKEN),
      vrfV2Wrapper: address(VRF_V2_WRAPPER_MOCK),
      linkPool: address(LINK_POOL),
      poolStorage: address(poolLotteryStorage),
      poolLotteryManager: address(poolLotteryManager)
    });

    poolLotteryStorage.transferOwnership(address(poolLottery));
    poolLotteryManager.setNewLottery(address(poolLottery));

    address newLottery = address(21);

    vm.expectEmit();
    emit IPoolLotteryManager.IPoolLotteryManager__upgradedLottery();
    poolLotteryManager.upgradeCurrentLottery(newLottery);
  }

  function test_changeLinkPool_withdrawLinkTokens() public {
    LinkPool oldLinkPool = LinkPool(poolLotteryManager.getLinkPool());
    uint256 oldLinkPoolBalance = LINK_TOKEN.balanceOf(address(oldLinkPool));

    LinkPool newLinkPool = new LinkPool(address(LINK_TOKEN), address(poolLotteryManager));

    poolLotteryManager.changeLinkPool(address(newLinkPool));

    assertEq(LINK_TOKEN.balanceOf(address(newLinkPool)), oldLinkPoolBalance);
    assertEq(LINK_TOKEN.balanceOf(address(oldLinkPool)), 0);
  }

  function test_changeLinkPool_emitsEvent() public {
    LinkPool newLinkPool = new LinkPool(address(LINK_TOKEN), address(poolLotteryManager));

    vm.expectEmit();
    emit IPoolLotteryManager.IPoolLotteryManager__LinkPoolChanged(address(newLinkPool));
    poolLotteryManager.changeLinkPool(address(newLinkPool));
  }
}
