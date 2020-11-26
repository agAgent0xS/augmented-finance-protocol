// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {IDelegationToken} from '../../interfaces/IDelegationToken.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {AToken} from './AToken.sol';

/**
 * @title Aave AToken enabled to delegate voting power of the underlying asset to a different address
 * @dev The underlying asset needs to be compatible with the COMP delegation interface
 * @author Aave
 */
contract DelegationAwareAToken is AToken {
  modifier onlyPoolAdmin {
    require(
      _msgSender() == ILendingPool(POOL).getAddressesProvider().getPoolAdmin(),
      Errors.CALLER_NOT_POOL_ADMIN
    );
    _;
  }

  constructor(
    ILendingPool pool,
    address underlyingAssetAddress,
    address reserveTreasury,
    string memory tokenName,
    string memory tokenSymbol,
    address incentivesController
  )
    public
    AToken(
      pool,
      underlyingAssetAddress,
      reserveTreasury,
      tokenName,
      tokenSymbol,
      incentivesController
    )
  {}

  function initialize(
    uint8 _underlyingAssetDecimals,
    string calldata _tokenName,
    string calldata _tokenSymbol
  ) external virtual override initializer {
    _setName(_tokenName);
    _setSymbol(_tokenSymbol);
    _setDecimals(_underlyingAssetDecimals);
  }

  /**
   * @dev Delegates voting power of the underlying asset to a `delegatee` address
   * @param delegatee The address that will receive the delegation
   **/
  function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
    IDelegationToken(UNDERLYING_ASSET_ADDRESS).delegate(delegatee);
  }
}