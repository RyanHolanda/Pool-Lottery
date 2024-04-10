// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

library Math {
    /**
     * @dev multiply the numbers in the array by each other.
     * e.g [1, 2, 3] => 1 * 2 * 3
     *
     * @dev pay attention to the underflow/overflow when passing the array.
     * this array can have at maximum 32 items equal to 255(32*255 = 1,02161150205×10⁷⁷), otherwise
     * it will overflow when multiplying them
     *
     */
    function multiplyBetween(uint256[] calldata numbers) external pure returns (uint256) {
        uint256 _result = numbers[0];
        uint256 numbersLength = numbers.length;
        for (uint256 i = 1; i < numbersLength; ++i) {
            _result = _result * numbers[i];
        }

        return _result;
    }
}
