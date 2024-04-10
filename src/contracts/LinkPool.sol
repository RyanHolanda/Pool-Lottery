//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ILinkPool} from "src/interfaces/ILinkPool.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @notice Link Token Holder to pay for Chainlink Services
 *
 * @dev This contract is responsible for holding LINK Tokens.
 * Any chainlink service which uses LINK Tokens for paying,
 * should use this contract.
 *
 * @custom:info To fund this contract just send the LINK tokens to the contract address.
 * **/
contract LinkPool is ILinkPool, Ownable {
  LinkTokenInterface private immutable i_linkToken;

  constructor(address linkToken, address owner) Ownable(owner) {
    i_linkToken = LinkTokenInterface(linkToken);
  }

  /// @inheritdoc ILinkPool
  function addSpender(address spender) external override onlyOwner {
    bool success = i_linkToken.approve(spender, type(uint256).max);

    if (!success) revert ILinkPool__FailedToAddSpender(spender);
  }

  /// @inheritdoc ILinkPool
  function removeSpender(address spender) external override onlyOwner {
    bool success = i_linkToken.approve(spender, 0);

    if (!success) revert ILinkPool__FailedToRemoveSpender(spender);
  }

  /// @inheritdoc ILinkPool
  function withdraw(address to) external override onlyOwner {
    bool success = i_linkToken.transfer(to, getBalance());

    if (!success) revert ILinkPool__withdrawFailed();
  }

  /// @inheritdoc ILinkPool
  function getBalance() public view override returns (uint256) {
    return i_linkToken.balanceOf(address(this));
  }
}
