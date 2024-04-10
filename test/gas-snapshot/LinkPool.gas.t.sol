// SPDX-License-Identifier:MIT
pragma solidity 0.8.25;

import {BaseTest} from "test/BaseTest.t.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {GasSnapshot} from "@forge-gas-snapshot/src/GasSnapshot.sol";

contract LinkPoolGasTest is BaseTest, GasSnapshot {
  ILinkPool public cut;

  function setUp() public override {
    super.setUp();
    cut = new LinkPool({linkToken: address(LINK_TOKEN), owner: address(this)});
  }

  function testGas_addSpender() public {
    setCheckMode(true);

    snapStart("LinkPool_AddSpender");
    cut.addSpender(USER);
    snapEnd();
  }

  function testGas_removeSpender() public {
    setCheckMode(true);

    cut.addSpender(USER);

    snapStart("LinkPool_RemoveSpender");
    cut.removeSpender(USER);
    snapEnd();
  }

  function testGas_withdraw() public {
    setCheckMode(true);

    LINK_TOKEN.mint(address(cut), 10000e18);

    snapStart("LinkPool_Withdraw");
    cut.withdraw(USER);
    snapEnd();
  }

  function testGas_getBalance() public {
    setCheckMode(true);

    LINK_TOKEN.mint(address(cut), 10000e18);

    snapStart("LinkPool_GetBalance");
    cut.getBalance();
    snapEnd();
  }
}
