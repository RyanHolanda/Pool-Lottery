// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {BaseTest} from "test/BaseTest.t.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LinkPoolStatelessFuzzTest is BaseTest {
  ILinkPool public cut;
  address public linkPoolOwner = address(this);
  uint256 public constant INITIAL_LINK_BALANCE = 10000000e18;

  function setUp() public override {
    super.setUp();
    cut = new LinkPool({linkToken: address(LINK_TOKEN), owner: linkPoolOwner});
    LINK_TOKEN.mint(address(cut), INITIAL_LINK_BALANCE);
  }

  function test_OwnerIsSetCorrectOnCreation(address owner) public {
    assumeNotZeroAddress(owner);
    LinkPool linkPool = new LinkPool({linkToken: address(LINK_TOKEN), owner: owner});

    assertEq(linkPool.owner(), address(owner));
  }

  function test_addSpender_revertsIfNotOwner(address notOwner, address spender) public {
    vm.assume(notOwner != linkPoolOwner);
    vm.assume(spender != notOwner);

    vm.startPrank(notOwner);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
    cut.addSpender(spender);

    vm.stopPrank();
  }

  function test_addSpender(address spender) public {
    assumeNotZeroAddress(spender);
    vm.assume(spender != address(LINK_TOKEN));

    cut.addSpender(spender);

    assertEq(LINK_TOKEN.allowance(address(cut), spender), type(uint256).max);
  }

  function test_removeSpender_revertsIfNotOwner(address notOwner, address spender) public {
    vm.assume(notOwner != linkPoolOwner);
    vm.assume(spender != notOwner);

    vm.startPrank(notOwner);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
    cut.removeSpender(spender);

    vm.stopPrank();
  }

  function test_removeSpender(address spender) public {
    vm.assume(spender != address(LINK_TOKEN));
    assumeNotZeroAddress(spender);

    cut.addSpender(spender);
    assertEq(
      LINK_TOKEN.allowance(address(cut), spender),
      type(uint256).max,
      "Spender should be added to set its allowance to zero"
    );

    cut.removeSpender(spender);

    assertEq(LINK_TOKEN.allowance(address(cut), spender), 0);
  }

  function test_withdraw_revertsIfNotOwner(address notOwner, address to) public {
    assumeNotZeroAddress(to);
    vm.assume(notOwner != linkPoolOwner);

    vm.startPrank(notOwner);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
    cut.withdraw(address(to));

    vm.stopPrank();
  }

  function test_withdraw(address to) public {
    assumeNotZeroAddress(to);
    vm.assume(to != address(LINK_TOKEN));
    vm.assume(LINK_TOKEN.balanceOf(to) == 0);

    uint256 poolBalanceBeforeWithdraw = LINK_TOKEN.balanceOf(address(cut));
    assertGt(poolBalanceBeforeWithdraw, 1, "Pool should have at least 1 LINK Token to test the withdraw");

    cut.withdraw(address(to));

    assertEq(LINK_TOKEN.balanceOf(address(cut)), 0);
    assertEq(LINK_TOKEN.balanceOf(to), poolBalanceBeforeWithdraw);
  }

  function test_getBalance(uint8 mintAmount) public {
    LINK_TOKEN.mint(address(cut), mintAmount);

    assertGt(cut.getBalance(), 1, "Pool should have at least 1 LINK Token to test the getBalance");
    assertEq(cut.getBalance(), LINK_TOKEN.balanceOf(address(cut)));
  }

  function test_fund(address user, uint32 userLinkBalance) public {
    vm.assume(user != address(cut));
    vm.assume(user != address(LINK_TOKEN));
    LINK_TOKEN.mint(user, userLinkBalance);

    uint256 contractBalanceBeforeFund = cut.getBalance();

    vm.startPrank(user);
    LINK_TOKEN.transfer(address(cut), userLinkBalance);
    vm.stopPrank();

    assertEq(cut.getBalance(), contractBalanceBeforeFund + userLinkBalance);
  }
}
