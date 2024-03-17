// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "@forge/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

abstract contract BaseTest is Test {
  address public constant USER = address(0x1234567890abcdef);
  uint256 public constant TICKET_PRICE = 1_000000000000000000;
  ERC20Mock public immutable MOCK_ERC_20 = new ERC20Mock();

  modifier userAsSender() {
    MOCK_ERC_20.mint(USER, TICKET_PRICE + 100 ether);
    vm.startPrank(USER);
    vm.deal(USER, 100 ether);
    _;
    vm.stopPrank();
  }

  function setUp() public virtual {
    MOCK_ERC_20.mint(USER, TICKET_PRICE + 100 ether);
  }

  function approveAndMintMockERC20(address spender, address to) public {
    MOCK_ERC_20.approve(spender, 1000000000000000000 ether);
    MOCK_ERC_20.mint(to, 1000000 ether);
  }
}
