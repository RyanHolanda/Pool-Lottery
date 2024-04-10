/// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Math} from "src/libraries/Math.sol";
import {BaseTest} from "test/BaseTest.t.sol";

contract MathTest is BaseTest {
  using Math for uint256[];

  function testMultiplyBetween() public {
    uint256[] memory numbers = new uint256[](3);
    numbers[0] = 12;
    numbers[1] = 23;
    numbers[2] = 7;
    uint256 expectedResult = 1932;

    uint256 result = numbers.multiplyBetween();
    assertEq(result, expectedResult);
  }
}
