// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {PercentageMath} from '../tools/math/PercentageMath.sol';

import {IMarketAccessController} from '../access/interfaces/IMarketAccessController.sol';
import {BaseRewardController} from './BaseRewardController.sol';
import {IRewardMinter} from '../interfaces/IRewardMinter.sol';
import {IRewardPool} from './interfaces/IRewardPool.sol';
import {IManagedRewardPool} from './interfaces/IManagedRewardPool.sol';
import {IBoostExcessReceiver} from './interfaces/IBoostExcessReceiver.sol';
import './interfaces/IAutolocker.sol';

import 'hardhat/console.sol';

enum BoostPoolRateUpdateMode {DefaultUpdateMode, BaselineLeftoverMode}

contract RewardBooster is BaseRewardController {
  using SafeMath for uint256;
  using PercentageMath for uint256;

  mapping(address => uint256) private _boostFactor;
  IManagedRewardPool private _boostPool;
  uint256 private _boostPoolMask;

  address private _boostExcessDelegate;
  bool private _mintExcess;
  BoostPoolRateUpdateMode private _boostRateMode;

  mapping(address => uint256) private _boostRewards;

  struct WorkReward {
    // saves some of storage cost
    uint128 claimableReward;
    uint128 boostLimit;
  }
  mapping(address => WorkReward) private _workRewards;

  constructor(IMarketAccessController accessController, IRewardMinter rewardMinter)
    public
    BaseRewardController(accessController, rewardMinter)
  {}

  function internalOnPoolRemoved(IManagedRewardPool pool) internal override {
    super.internalOnPoolRemoved(pool);
    if (_boostPool == pool) {
      _boostPool = IManagedRewardPool(0);
      _boostPoolMask = 0;
    } else {
      delete (_boostFactor[address(pool)]);
    }
  }

  function setBoostFactor(address pool, uint32 pctFactor) external {
    require(
      isConfigurator(msg.sender) || isRateController(msg.sender),
      'only owner, configurator or rate controller are allowed'
    );
    require(getPoolMask(pool) != 0, 'unknown pool');
    require(pool != address(_boostPool), 'factor for the boost pool');
    _boostFactor[pool] = pctFactor;
  }

  function getBoostFactor(address pool) external view returns (uint32 pctFactor) {
    return uint32(_boostFactor[pool]);
  }

  function setBoostPoolRateUpdateMode(BoostPoolRateUpdateMode mode) external onlyConfigurator {
    _boostRateMode = mode;
  }

  function internalUpdateBaseline(uint256 baseline, uint256 baselineMask)
    internal
    override
    returns (uint256 totalRate, uint256)
  {
    if (_boostPoolMask == 0 || _boostRateMode == BoostPoolRateUpdateMode.DefaultUpdateMode) {
      return super.internalUpdateBaseline(baseline, baselineMask);
    }

    (totalRate, baselineMask) = super.internalUpdateBaseline(
      baseline,
      baselineMask & ~_boostPoolMask
    );
    if (totalRate < baseline) {
      _boostPool.setRate(baseline - totalRate);
      totalRate = baseline;
    } else {
      _boostPool.setRate(0);
    }

    return (totalRate, baselineMask);
  }

  function setBoostPool(address pool) external onlyConfigurator {
    if (pool == address(0)) {
      _boostPoolMask = 0;
    } else {
      uint256 mask = getPoolMask(pool);
      require(mask != 0, 'unknown pool');
      _boostPoolMask = mask;

      delete (_boostFactor[pool]);
    }
    _boostPool = IManagedRewardPool(pool);
  }

  function getBoostPool() external view returns (address) {
    return address(_boostPool);
  }

  function setBoostExcessTarget(address target, bool mintExcess) external onlyConfigurator {
    _boostExcessDelegate = target;
    _mintExcess = mintExcess && (target != address(0));
  }

  function getBoostExcessTarget() external view returns (address target, bool mintExcess) {
    return (_boostExcessDelegate, _mintExcess);
  }

  function getClaimMask(address holder, uint256 mask) internal view override returns (uint256) {
    mask = super.getClaimMask(holder, mask);
    mask &= ~_boostPoolMask;
    return mask;
  }

  function internalClaimAndMintReward(address holder, uint256 mask)
    internal
    override
    returns (uint256 claimableAmount)
  {
    uint256 boostLimit;
    (claimableAmount, boostLimit) = (
      _workRewards[holder].claimableReward,
      _workRewards[holder].boostLimit
    );

    if (boostLimit > 0 || claimableAmount > 0) {
      delete (_workRewards[holder]);
    }

    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      IManagedRewardPool pool = getPool(i);
      (uint256 amount_, ) = pool.claimRewardFor(holder, type(uint256).max);
      if (amount_ == 0) {
        continue;
      }

      claimableAmount = claimableAmount.add(amount_);
      boostLimit = boostLimit.add(amount_.percentMul(_boostFactor[address(pool)]));
    }

    uint256 boost = _boostRewards[holder];
    if (boost > 0) {
      delete (_boostRewards[holder]);
    }

    uint32 boostSince;
    if (_boostPool != IManagedRewardPool(0)) {
      uint256 boost_;

      if (_mintExcess || _boostExcessDelegate != address(_boostPool)) {
        (boost_, boostSince) = _boostPool.claimRewardFor(holder, type(uint256).max);
      } else {
        uint256 boostLimit_;
        if (boostLimit > boost) {
          boostLimit_ = boostLimit - boost;
        }
        (boost_, boostSince) = _boostPool.claimRewardFor(holder, boostLimit_);
      }

      boost = boost.add(boost_);
    }

    // console.log('internalClaimAndMintReward', claimableAmount, boostLimit, boost);

    if (boost <= boostLimit) {
      claimableAmount = claimableAmount.add(boost);
    } else {
      claimableAmount = claimableAmount.add(boostLimit);
      internalStoreBoostExcess(boost - boostLimit, boostSince);
    }

    return claimableAmount;
  }

  function internalCalcClaimableReward(address holder, uint256 mask)
    internal
    view
    override
    returns (uint256 claimableAmount, uint256)
  {
    uint256 boostLimit;
    (claimableAmount, boostLimit) = (
      _workRewards[holder].claimableReward,
      _workRewards[holder].boostLimit
    );

    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      IManagedRewardPool pool = getPool(i);
      (uint256 amount_, ) = pool.calcRewardFor(holder);
      if (amount_ == 0) {
        continue;
      }

      claimableAmount = claimableAmount.add(amount_);
      boostLimit = boostLimit.add(amount_.percentMul(_boostFactor[address(pool)]));
    }

    uint256 boost = _boostRewards[holder];

    if (_boostPool != IManagedRewardPool(0)) {
      (uint256 boost_, ) = _boostPool.calcRewardFor(holder);
      boost = boost.add(boost_);
    }

    if (boost <= boostLimit) {
      claimableAmount = claimableAmount.add(boost);
    } else {
      claimableAmount = claimableAmount.add(boostLimit);
    }

    return (claimableAmount, 0);
  }

  function internalAllocatedByPool(
    address holder,
    uint256 allocated,
    address pool,
    uint32
  ) internal override {
    if (address(_boostPool) == pool) {
      _boostRewards[holder] = _boostRewards[holder].add(allocated);
      return;
    }

    WorkReward memory workReward = _workRewards[holder];

    uint256 v = uint256(workReward.claimableReward).add(allocated);
    require(v <= type(uint128).max);
    workReward.claimableReward = uint128(v);

    uint256 factor = _boostFactor[pool];
    if (factor != 0) {
      v = uint256(workReward.boostLimit).add(allocated.mul(factor));
      require(v <= type(uint128).max);
      workReward.boostLimit = uint128(v);
    }

    _workRewards[holder] = workReward;
  }

  function internalStoreBoostExcess(uint256 boostExcess, uint32 since) private {
    if (_boostExcessDelegate == address(0)) {
      return;
    }

    if (_mintExcess) {
      internalMint(_boostExcessDelegate, boostExcess, true);
      return;
    }

    IBoostExcessReceiver(_boostExcessDelegate).receiveBoostExcess(boostExcess, since);
  }

  struct AutolockEntry {
    uint224 param;
    AutolockMode mode;
    uint8 lockDuration;
  }

  mapping(address => AutolockEntry) private _autolocks;
  AutolockEntry private _defaultAutolock;

  function disableAutolocks() external {
    require(
      isConfigurator(msg.sender) || isRateController(msg.sender),
      'only owner, configurator or rate controller are allowed'
    );
    _defaultAutolock = AutolockEntry(0, AutolockMode.Default, 0);
  }

  function setDefaultAutolock(
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  ) external {
    require(
      isConfigurator(msg.sender) || isRateController(msg.sender),
      'only owner, configurator or rate controller are allowed'
    );
    require(mode > AutolockMode.Default);

    _defaultAutolock = AutolockEntry(param, mode, fromDuration(lockDuration));
  }

  function fromDuration(uint32 lockDuration) private pure returns (uint8) {
    require(lockDuration % 1 weeks == 0, 'duration must be in weeks');
    uint256 v = lockDuration / 1 weeks;
    require(v <= 4 * 52, 'duration must be less than 209 weeks');
    return uint8(v);
  }

  function autolockProlongate(uint32 minLockDuration) external {
    _autolocks[msg.sender] = AutolockEntry(
      0,
      AutolockMode.Prolongate,
      fromDuration(minLockDuration)
    );
  }

  function autolockAccumulateUnderlying(uint256 maxAmount, uint32 lockDuration) external {
    require(maxAmount > 0, 'max amount is required');
    if (maxAmount > type(uint224).max) {
      maxAmount = type(uint224).max;
    }

    _autolocks[msg.sender] = AutolockEntry(
      uint224(maxAmount),
      AutolockMode.AccumulateUnderlying,
      fromDuration(lockDuration)
    );
  }

  function autolockAccumulateTill(uint256 timestamp, uint32 lockDuration) external {
    require(timestamp > block.timestamp, 'future timestamp is required');
    if (timestamp > type(uint224).max) {
      timestamp = type(uint224).max;
    }
    _autolocks[msg.sender] = AutolockEntry(
      uint224(timestamp),
      AutolockMode.AccumulateTill,
      fromDuration(lockDuration)
    );
  }

  function autolockKeepUpBalance(uint256 minAmount, uint32 lockDuration) external {
    require(minAmount > 0, 'min amount is required');
    if (minAmount > type(uint224).max) {
      minAmount = type(uint224).max;
    }
    _autolocks[msg.sender] = AutolockEntry(
      uint224(minAmount),
      AutolockMode.KeepUpBalance,
      fromDuration(lockDuration)
    );
  }

  function autolockStop() external {
    _autolocks[msg.sender] = AutolockEntry(0, AutolockMode.Stop, 0);
  }

  function autolockOf(address account)
    public
    view
    returns (
      AutolockMode mode,
      uint32 lockDuration,
      uint256 param
    )
  {
    AutolockEntry memory entry = _autolocks[account];
    if (entry.mode == AutolockMode.Default) {
      entry = _defaultAutolock;
    }
    return (entry.mode, entry.lockDuration * 1 weeks, entry.param);
  }

  function applyAutolock(
    address holder,
    uint256 amount,
    AutolockEntry memory entry
  ) private returns (uint256) {
    (address receiver, uint256 lockAmount) =
      IAutolocker(address(_boostPool)).applyAutolock(
        holder,
        amount,
        entry.mode,
        entry.lockDuration * 1 weeks,
        entry.param
      );

    if (receiver != address(0) && lockAmount > 0) {
      internalMint(receiver, lockAmount, true);
      return amount.sub(lockAmount);
    }

    return amount;
  }

  function internalClaimed(
    address holder,
    address mintTo,
    uint256 amount
  ) internal override {
    if (address(_boostPool) == address(0)) {
      internalMint(mintTo, amount, false);
      return;
    }

    AutolockEntry memory entry = _autolocks[holder];
    if (entry.mode == AutolockMode.Stop || _defaultAutolock.mode == AutolockMode.Default) {
      internalMint(mintTo, amount, false);
      return;
    }

    if (entry.mode == AutolockMode.Default) {
      entry = _defaultAutolock;
      if (entry.mode == AutolockMode.Stop) {
        internalMint(mintTo, amount, false);
        return;
      }
    }

    amount = applyAutolock(holder, amount, entry);
    if (amount > 0) {
      internalMint(mintTo, amount, false);
    }
  }
}
