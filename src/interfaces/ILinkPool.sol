// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ILinkPool {
  error ILinkPool__withdrawFailed();

  error ILinkPool__FailedToAddSpender(address spender);

  error ILinkPool__FailedToRemoveSpender(address spender);

  /// @notice approve a spender to transfer assets from the pool
  function addSpender(address spender) external;

  /// @notice decrease the spend allowance to zero
  function removeSpender(address spender) external;

  /// @notice withdraw LINK Tokens from the pool
  /// @param to the address to send the assets
  function withdraw(address to) external;

  /// @notice get the LINK Tokens balance of the pool
  function getBalance() external view returns (uint256);
}
