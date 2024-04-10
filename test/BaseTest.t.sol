// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "@forge/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {LinkToken} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/LinkToken.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";
import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {VRFV2WrapperMock} from "test/mocks/VRFV2WrapperMock.sol";

abstract contract BaseTest is Test {
  using Strings for uint256;

  address public constant USER = address(0x1234567890abcdef);
  uint256 public constant TICKET_PRICE = 1_000000000000000000;
  uint256 public constant LOTTERY_DURATION = 24 hours;
  uint32 public constant VRF_NUM_WORDS_TO_REQUEST = 20;
  uint32 public constant VRF_CALLBACK_GAS_LIMIT = 2_500_000;
  uint16 public constant VRF_MINIMUM_REQUEST_CONFIRMATIONS = 3;

  ERC20Mock public immutable MOCK_ERC_20 = new ERC20Mock();
  LinkToken public immutable LINK_TOKEN = new LinkToken();
  MockLinkToken public immutable MOCK_LINK_TOKEN = new MockLinkToken();
  ILinkPool public immutable LINK_POOL = new LinkPool({linkToken: address(LINK_TOKEN), owner: address(this)});
  VRFV2WrapperMock public immutable VRF_V2_WRAPPER_MOCK = new VRFV2WrapperMock();

  address public lastRandomUser;

  modifier userAsSender() {
    MOCK_ERC_20.mint(USER, TICKET_PRICE);
    vm.startPrank(USER);
    vm.deal(USER, 100 ether);
    _;
    vm.stopPrank();
  }

  modifier randomUser() {
    vm.roll(block.number + 1);
    lastRandomUser = makeAddr(block.number.toString());
    vm.startPrank(lastRandomUser);
    _;
    vm.stopPrank();
  }

  modifier useLastRandomUser() {
    vm.startPrank(lastRandomUser);
    _;
    vm.stopPrank();
  }

  function setUp() public virtual {
    MOCK_ERC_20.mint(USER, 100e64);
    LINK_TOKEN.grantMintRole(address(this));
    LINK_TOKEN.mint(address(LINK_POOL), 100000e18);
    LINK_POOL.addSpender(address(this));
  }

  function approveAndMintMockERC20(address spender, address to) public {
    MOCK_ERC_20.mint(to, 100000000000000000 ether);
    MOCK_ERC_20.approve(spender, 1000000000000000000 ether);
  }

  function approveAndMintMockERC20(address spender, address to, uint256 mintAmount) public {
    MOCK_ERC_20.approve(spender, 1000000000000000000 ether);
    MOCK_ERC_20.mint(to, mintAmount);
  }

  function mintMockERC20(address to, uint256 amount) public {
    MOCK_ERC_20.mint(to, amount);
  }

  /// @dev A dummy test to not include this file in coverage report
  function test() public pure virtual {
    assert(true);
  }
}
