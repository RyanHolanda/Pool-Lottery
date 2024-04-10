// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";

interface IPoolLotteryManager {
  /// @notice emitted once a new lottery is set
  event IPoolLotteryManager__NewLottery(address indexed lottery);

  /// @notice emitted once the current lottery is upgraded(but the storage is not changed)
  event IPoolLotteryManager__upgradedLottery();

  /// @notice emitted once the link pool address is changed
  event IPoolLotteryManager__LinkPoolChanged(address indexed newLinkPool);

  /// @notice thrown when the manager is not the owner of the link pool
  error IPoolLotteryManager__ManagerNotOwnerOfLinkPool();

  /// @notice set a new lottery
  function setNewLottery(address newLottery) external;

  /// @notice upgrade the current lottery maintening the same storage
  /// @param newImpl the address of the new implementation
  function upgradeCurrentLottery(address newImpl) external;

  /// @notice set a new link pool to get link tokens from
  function changeLinkPool(address newLinkPool) external;

  /// @notice returns the current lottery
  function getCurrentLottery() external view returns (IPoolLottery);

  /// @notice returns the address of the link pool
  function getLinkPool() external view returns (address);
}
