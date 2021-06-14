// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {BitUtils} from '../tools/math/BitUtils.sol';

import {IMarketAccessController} from '../access/interfaces/IMarketAccessController.sol';
import {IRewardMinter} from '../interfaces/IRewardMinter.sol';
import {BaseRewardController} from './BaseRewardController.sol';

import 'hardhat/console.sol';

abstract contract BasicRewardController is BaseRewardController {
  using SafeMath for uint256;

  constructor(IMarketAccessController accessController, IRewardMinter rewardMinter)
    public
    BaseRewardController(accessController, rewardMinter)
  {}

  function internalClaimAndMintReward(address holder, uint256 mask)
    internal
    override
    returns (uint256 claimableAmount)
  {
    uint32 sinceBlock = 0;
    uint256 amountSince = 0;
    bool incremental = false;

    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      (uint256 amount_, uint32 since_) = getPool(i).claimRewardFor(holder);
      if (amount_ == 0) {
        continue;
      }

      if (sinceBlock == since_) {
        amountSince = amountSince.add(amount_);
        continue;
      }

      if (amountSince > 0) {
        claimableAmount = claimableAmount.add(internalClaimByCall(holder, amountSince, sinceBlock));
        incremental = true;
      }
      amountSince = amount_;
      sinceBlock = since_;
    }

    if (amountSince > 0 || !incremental) {
      claimableAmount = claimableAmount.add(internalClaimByCall(holder, amountSince, sinceBlock));
    }

    return claimableAmount;
  }

  function internalCalcClaimableReward(address holder, uint256 mask)
    internal
    view
    override
    returns (uint256 claimableAmount, uint256 delayedAmount)
  {
    uint32 sinceBlock = 0;
    uint256 amountSince = 0;
    bool incremental = false;

    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      (uint256 amount_, uint32 since_) = getPool(i).calcRewardFor(holder);
      if (amount_ == 0) {
        continue;
      }

      if (sinceBlock == since_) {
        amountSince = amountSince.add(amount_);
        continue;
      }

      if (amountSince > 0) {
        (uint256 ca, uint256 da) = internalCalcByCall(holder, amountSince, sinceBlock, incremental);
        claimableAmount = claimableAmount.add(ca);
        delayedAmount = delayedAmount.add(da);
        incremental = true;
      }
      amountSince = amount_;
      sinceBlock = since_;
    }

    if (amountSince > 0 || !incremental) {
      (uint256 ca, uint256 da) = internalCalcByCall(holder, amountSince, sinceBlock, incremental);
      claimableAmount = claimableAmount.add(ca);
      delayedAmount = delayedAmount.add(da);
    }

    return (claimableAmount, delayedAmount);
  }

  function internalClaimByCall(
    address holder,
    uint256 allocated,
    uint32 sinceBlock
  ) internal virtual returns (uint256 amount);

  function internalCalcByCall(
    address holder,
    uint256 allocated,
    uint32 sinceBlock,
    bool incremental
  ) internal view virtual returns (uint256 claimableAmount, uint256 delayedAmount);
}
