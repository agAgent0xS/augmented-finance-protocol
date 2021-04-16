// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IDerivedToken} from '../../../interfaces/IDerivedToken.sol';

interface IStakeToken is IDerivedToken {
  function stake(address to, uint256 underlyingAmount) external returns (uint256 stakeAmount);

  function redeem(address to, uint256 maxStakeAmount) external returns (uint256 stakeAmount);

  function redeemUnderlying(address to, uint256 maxUnderlyingAmount)
    external
    returns (uint256 underlyingAmount);

  function cooldown() external;

  function getCooldown(address) external returns (uint40);

  function exchangeRate() external view returns (uint256);

  function isRedeemable() external view returns (bool);

  function slashUnderlying(
    address destination,
    uint256 minAmount,
    uint256 maxAmount
  ) external returns (uint256);
}

interface IManagedStakeToken is IStakeToken {
  function setRedeemable(bool redeemable) external;

  function getMaxSlashablePercentage() external view returns (uint256);

  function setMaxSlashablePercentage(uint256 percentage) external;
}
