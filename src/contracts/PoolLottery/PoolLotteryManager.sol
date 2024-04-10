// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PoolLottery} from "src/contracts/PoolLottery/PoolLottery.sol";
import {IPoolLottery} from "src/interfaces/IPoolLottery.sol";
import {IPoolLotteryManager} from "src/interfaces/IPoolLotteryManager.sol";
import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {LinkPool} from "src/contracts/LinkPool.sol";

contract PoolLotteryManager is Ownable, IPoolLotteryManager {
  IPoolLottery private s_currentLottery;
  ILinkPool private s_linkPool;

  constructor(address owner, address linkPool) Ownable(owner) {
    LinkPool _linkPool = LinkPool(linkPool);
    s_linkPool = _linkPool;
  }

  /// @inheritdoc IPoolLotteryManager
  function setNewLottery(address newLottery) external override onlyOwner {
    _rawSetNewLottery(newLottery);

    emit IPoolLotteryManager__NewLottery(newLottery);
  }

  /// @inheritdoc IPoolLotteryManager
  function upgradeCurrentLottery(address newImpl) external override onlyOwner {
    PoolLottery oldImpl = PoolLottery(address(s_currentLottery));
    oldImpl.transferStorageOwnership(newImpl);
    _rawSetNewLottery(newImpl);

    emit IPoolLotteryManager__upgradedLottery();
  }

  /// @inheritdoc IPoolLotteryManager
  function changeLinkPool(address newLinkPool) external override onlyOwner {
    s_linkPool.withdraw({to: newLinkPool});

    LinkPool _linkPool = LinkPool(newLinkPool);
    s_linkPool = _linkPool;

    if (_linkPool.owner() != address(this)) revert IPoolLotteryManager__ManagerNotOwnerOfLinkPool();

    emit IPoolLotteryManager__LinkPoolChanged(newLinkPool);
  }

  /// @inheritdoc IPoolLotteryManager
  function getCurrentLottery() external view override returns (IPoolLottery) {
    return s_currentLottery;
  }

  /// @inheritdoc IPoolLotteryManager
  function getLinkPool() external view override returns (address) {
    return address(s_linkPool);
  }

  function _rawSetNewLottery(address newLottery) private {
    address _currentLottery = address(s_currentLottery);

    if (_currentLottery != address(0)) s_linkPool.removeSpender(address(_currentLottery));

    s_currentLottery = IPoolLottery(PoolLottery(newLottery));
    s_linkPool.addSpender(newLottery);
  }
}
