/// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Math} from "src/libraries/Math.sol";
import {BaseTest} from "test/BaseTest.t.sol";

contract MathStatelessFuzzTest is BaseTest {
  using Math for uint256[];

  function testMultiplyBetween(uint256 firstNumber, uint256 secondNumber, uint256 thirdNumber) public {
    uint256 safeNumberToNotOverflow = 157165237895;

    firstNumber = bound(firstNumber, 0, safeNumberToNotOverflow);
    secondNumber = bound(secondNumber, 0, safeNumberToNotOverflow);
    thirdNumber = bound(thirdNumber, 0, safeNumberToNotOverflow);

    uint256 expectedResult = (firstNumber * secondNumber * thirdNumber);
    uint256[] memory numbers = new uint256[](3);

    numbers[0] = firstNumber;
    numbers[1] = secondNumber;
    numbers[2] = thirdNumber;

    uint256 result = numbers.multiplyBetween();
    assertEq(result, expectedResult);
  }
}
