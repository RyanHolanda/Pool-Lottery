// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract LinkPoolTest is BaseTest {
  ILinkPool public linkPool;

  function setUp() public override {
    super.setUp();

    linkPool = new LinkPool({linkToken: address(LINK_TOKEN), owner: address(this)});
  }

  function test_addSpender_revertsIfApproveReturnsFalse() public {
    vm.mockCall(address(LINK_TOKEN), abi.encodeWithSelector(LINK_TOKEN.approve.selector), abi.encode(false));

    vm.expectRevert(abi.encodeWithSelector(ILinkPool.ILinkPool__FailedToAddSpender.selector, 1));
    linkPool.addSpender(address(1));
  }

  function test_removeSpender_revertsIfApproveReturnsFalse() public {
    vm.mockCall(address(LINK_TOKEN), abi.encodeWithSelector(LINK_TOKEN.approve.selector), abi.encode(false));

    vm.expectRevert(abi.encodeWithSelector(ILinkPool.ILinkPool__FailedToRemoveSpender.selector, 1));
    linkPool.removeSpender(address(1));
  }

  function test_withdraw_revertsIfTransferReturnsFalse() public {
    vm.mockCall(address(LINK_TOKEN), abi.encodeWithSelector(LINK_TOKEN.transfer.selector), abi.encode(false));

    vm.expectRevert(abi.encodeWithSelector(ILinkPool.ILinkPool__withdrawFailed.selector));
    linkPool.withdraw(address(1));
  }
}
