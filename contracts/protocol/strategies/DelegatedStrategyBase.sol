// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IReserveDelegatedStrategy.sol';

abstract contract DelegatedStrategyBase is IReserveDelegatedStrategy {
  address private immutable self = address(this);
  string private _name;

  constructor(string memory name) {
    _name = name;
  }

  function isDelegatedReserve() external pure override returns (bool) {
    return true;
  }

  function getStrategyName() external view override returns (string memory) {
    return _name;
  }

  function delegatedWithdrawUnderlying(
    address asset,
    uint256 amount,
    address to
  ) external override returns (uint256) {
    require(self != address(this), 'only delegated');
    require(amount > 0);
    return internalWithdrawUnderlying(asset, amount, to);
  }

  function internalWithdrawUnderlying(
    address asset,
    uint256 amount,
    address to
  ) internal virtual returns (uint256);
}
