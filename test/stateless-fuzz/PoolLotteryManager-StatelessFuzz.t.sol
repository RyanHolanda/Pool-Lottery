// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {PoolLotteryManager} from "src/contracts/PoolLottery/PoolLotteryManager.sol";
import {IPoolLotteryManager} from "src/interfaces/IPoolLotteryManager.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PoolLotteryManagerStatelessFuzzTest is BaseTest {
  IPoolLotteryManager public poolLotteryManager;

  function setUp() public override {
    super.setUp();

    poolLotteryManager = new PoolLotteryManager(address(this), address(LINK_POOL));
    LinkPool(address(LINK_POOL)).transferOwnership(address(poolLotteryManager));
  }

  function test_setNewLottery_revertsIfNotOwner(address notOwner, address newLottery) public {
    vm.assume(notOwner != address(this));

    vm.startPrank(notOwner);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
    poolLotteryManager.setNewLottery(newLottery);

    vm.stopPrank();
  }

  function test_setNewLottery_removesTheOldLotteryAsLinkSpender(address newLottery, address oldLottery) public {
    assumeNotZeroAddress(newLottery);
    assumeNotZeroAddress(oldLottery);
    vm.assume(newLottery != oldLottery);
    vm.assume(newLottery != address(LINK_TOKEN) && oldLottery != address(LINK_TOKEN));

    poolLotteryManager.setNewLottery(oldLottery);

    vm.expectCall(
      address(LINK_POOL),
      abi.encodeWithSelector(LINK_POOL.removeSpender.selector, address(poolLotteryManager.getCurrentLottery()))
    );
    poolLotteryManager.setNewLottery(newLottery);
  }

  function test_setNewLottery_addNewLotteryAsLinkSpender(address newLottery) public {
    assumeNotZeroAddress(newLottery);
    vm.assume(newLottery != address(LINK_TOKEN));

    vm.expectCall(address(LINK_POOL), abi.encodeWithSelector(LINK_POOL.addSpender.selector, newLottery));
    poolLotteryManager.setNewLottery(newLottery);
  }

  function test_upgradeCurrentLottery_revertsIfNotOwner(address notOwner) public {
    vm.assume(notOwner != address(this));

    vm.startPrank(notOwner);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
    poolLotteryManager.upgradeCurrentLottery(address(poolLotteryManager));
    vm.stopPrank();
  }

  function test_changeLinkPool_revertsIfNotOwner(address notOwner) public {
    vm.assume(notOwner != address(this));
    vm.startPrank(notOwner);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
    poolLotteryManager.changeLinkPool(address(LINK_POOL));

    vm.stopPrank();
  }

  function test_changeLinkPool_revertsIfLinkPoolOwnerIsNotPoolLotteryManager(address notPoolManager) public {
    vm.assume(notPoolManager != address(poolLotteryManager));

    LinkPool newLinkPool = new LinkPool(address(LINK_TOKEN), notPoolManager);

    vm.expectRevert(IPoolLotteryManager.IPoolLotteryManager__ManagerNotOwnerOfLinkPool.selector);
    poolLotteryManager.changeLinkPool(address(newLinkPool));
  }

  function test_getCurrentLottery(address newLottery) public {
    assumeNotZeroAddress(newLottery);
    vm.assume(newLottery != address(LINK_TOKEN));
    poolLotteryManager.setNewLottery(newLottery);

    assertEq(address(poolLotteryManager.getCurrentLottery()), address(newLottery));
  }

  function test_getLinkPool(address linkPool) public {
    IPoolLotteryManager _poolLotteryManager = new PoolLotteryManager(address(this), address(linkPool));

    assertEq(_poolLotteryManager.getLinkPool(), linkPool);
  }
}
