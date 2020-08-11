/* Generated by ts-generator ver. 0.0.8 */
/* tslint:disable */

import { Contract, ContractTransaction, EventFilter, Signer } from "ethers";
import { Listener, Provider } from "ethers/providers";
import { Arrayish, BigNumber, BigNumberish, Interface } from "ethers/utils";
import {
  TransactionOverrides,
  TypedEventDescription,
  TypedFunctionDescription
} from ".";

interface ILendingPoolAddressesProviderInterface extends Interface {
  functions: {
    getFeeProvider: TypedFunctionDescription<{ encode([]: []): string }>;

    getLendingPool: TypedFunctionDescription<{ encode([]: []): string }>;

    getLendingPoolConfigurator: TypedFunctionDescription<{
      encode([]: []): string;
    }>;

    getLendingPoolLiquidationManager: TypedFunctionDescription<{
      encode([]: []): string;
    }>;

    getLendingPoolManager: TypedFunctionDescription<{ encode([]: []): string }>;

    getLendingRateOracle: TypedFunctionDescription<{ encode([]: []): string }>;

    getPriceOracle: TypedFunctionDescription<{ encode([]: []): string }>;

    getTokenDistributor: TypedFunctionDescription<{ encode([]: []): string }>;

    setFeeProviderImpl: TypedFunctionDescription<{
      encode([_feeProvider]: [string]): string;
    }>;

    setLendingPoolConfiguratorImpl: TypedFunctionDescription<{
      encode([_configurator]: [string]): string;
    }>;

    setLendingPoolImpl: TypedFunctionDescription<{
      encode([_pool]: [string]): string;
    }>;

    setLendingPoolLiquidationManager: TypedFunctionDescription<{
      encode([_manager]: [string]): string;
    }>;

    setLendingPoolManager: TypedFunctionDescription<{
      encode([_lendingPoolManager]: [string]): string;
    }>;

    setLendingRateOracle: TypedFunctionDescription<{
      encode([_lendingRateOracle]: [string]): string;
    }>;

    setPriceOracle: TypedFunctionDescription<{
      encode([_priceOracle]: [string]): string;
    }>;

    setTokenDistributor: TypedFunctionDescription<{
      encode([_tokenDistributor]: [string]): string;
    }>;
  };

  events: {};
}

export class ILendingPoolAddressesProvider extends Contract {
  connect(
    signerOrProvider: Signer | Provider | string
  ): ILendingPoolAddressesProvider;
  attach(addressOrName: string): ILendingPoolAddressesProvider;
  deployed(): Promise<ILendingPoolAddressesProvider>;

  on(
    event: EventFilter | string,
    listener: Listener
  ): ILendingPoolAddressesProvider;
  once(
    event: EventFilter | string,
    listener: Listener
  ): ILendingPoolAddressesProvider;
  addListener(
    eventName: EventFilter | string,
    listener: Listener
  ): ILendingPoolAddressesProvider;
  removeAllListeners(
    eventName: EventFilter | string
  ): ILendingPoolAddressesProvider;
  removeListener(
    eventName: any,
    listener: Listener
  ): ILendingPoolAddressesProvider;

  interface: ILendingPoolAddressesProviderInterface;

  functions: {
    getFeeProvider(): Promise<string>;

    getLendingPool(): Promise<string>;

    getLendingPoolConfigurator(): Promise<string>;

    getLendingPoolLiquidationManager(): Promise<string>;

    getLendingPoolManager(): Promise<string>;

    getLendingRateOracle(): Promise<string>;

    getPriceOracle(): Promise<string>;

    getTokenDistributor(): Promise<string>;

    setFeeProviderImpl(
      _feeProvider: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setLendingPoolConfiguratorImpl(
      _configurator: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setLendingPoolImpl(
      _pool: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setLendingPoolLiquidationManager(
      _manager: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setLendingPoolManager(
      _lendingPoolManager: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setLendingRateOracle(
      _lendingRateOracle: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setPriceOracle(
      _priceOracle: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;

    setTokenDistributor(
      _tokenDistributor: string,
      overrides?: TransactionOverrides
    ): Promise<ContractTransaction>;
  };

  getFeeProvider(): Promise<string>;

  getLendingPool(): Promise<string>;

  getLendingPoolConfigurator(): Promise<string>;

  getLendingPoolLiquidationManager(): Promise<string>;

  getLendingPoolManager(): Promise<string>;

  getLendingRateOracle(): Promise<string>;

  getPriceOracle(): Promise<string>;

  getTokenDistributor(): Promise<string>;

  setFeeProviderImpl(
    _feeProvider: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setLendingPoolConfiguratorImpl(
    _configurator: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setLendingPoolImpl(
    _pool: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setLendingPoolLiquidationManager(
    _manager: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setLendingPoolManager(
    _lendingPoolManager: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setLendingRateOracle(
    _lendingRateOracle: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setPriceOracle(
    _priceOracle: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  setTokenDistributor(
    _tokenDistributor: string,
    overrides?: TransactionOverrides
  ): Promise<ContractTransaction>;

  filters: {};

  estimate: {
    getFeeProvider(): Promise<BigNumber>;

    getLendingPool(): Promise<BigNumber>;

    getLendingPoolConfigurator(): Promise<BigNumber>;

    getLendingPoolLiquidationManager(): Promise<BigNumber>;

    getLendingPoolManager(): Promise<BigNumber>;

    getLendingRateOracle(): Promise<BigNumber>;

    getPriceOracle(): Promise<BigNumber>;

    getTokenDistributor(): Promise<BigNumber>;

    setFeeProviderImpl(_feeProvider: string): Promise<BigNumber>;

    setLendingPoolConfiguratorImpl(_configurator: string): Promise<BigNumber>;

    setLendingPoolImpl(_pool: string): Promise<BigNumber>;

    setLendingPoolLiquidationManager(_manager: string): Promise<BigNumber>;

    setLendingPoolManager(_lendingPoolManager: string): Promise<BigNumber>;

    setLendingRateOracle(_lendingRateOracle: string): Promise<BigNumber>;

    setPriceOracle(_priceOracle: string): Promise<BigNumber>;

    setTokenDistributor(_tokenDistributor: string): Promise<BigNumber>;
  };
}