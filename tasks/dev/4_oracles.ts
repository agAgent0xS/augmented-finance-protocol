import { task } from 'hardhat/config';
import {
  deployMockPriceOracle,
  deployOracleRouter,
  deployLendingRateOracle,
} from '../../helpers/contracts-deployments';
import {
  setInitialAssetPricesInOracle,
  deployAllMockAggregators,
  setInitialMarketRatesInRatesOracleByHelper,
} from '../../helpers/oracles-helpers';
import { ICommonConfiguration, iAssetBase, DefaultTokenSymbols, tEthereumAddress } from '../../helpers/types';
import { getFirstSigner, waitForTx } from '../../helpers/misc-utils';
import { getAllAggregatorsAddresses, getAllTokenAddresses } from '../../helpers/mock-helpers';
import { ConfigNames, loadPoolConfig, getOrCreateWethAddress } from '../../helpers/configuration';
import {
  getAllMockedTokens,
  getMarketAddressController,
  getTokenAggregatorPairs,
} from '../../helpers/contracts-getters';
import { AccessFlags } from '../../helpers/access-flags';

task('dev:deploy-oracles', 'Deploy oracles for dev enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .addParam('pool', `Pool name to retrieve configuration, supported: ${Object.values(ConfigNames)}`)
  .setAction(async ({ verify, pool }, localBRE) => {
    await localBRE.run('set-DRE');
    const poolConfig = loadPoolConfig(pool);
    const {
      Mocks: { UsdAddress, MockUsdPriceInWei, AllAssetsInitialPrices },
      LendingRateOracleRates,
    } = poolConfig as ICommonConfiguration;

    const defaultTokenList = {
      ...Object.fromEntries(DefaultTokenSymbols.map((symbol) => [symbol, ''])),
      USD: UsdAddress,
    } as { [key: string]: tEthereumAddress };
    const mockTokens = await getAllMockedTokens();
    const mockTokensAddress = Object.keys(mockTokens).reduce<{ [key: string]: tEthereumAddress }>((prev, curr) => {
      prev[curr as keyof iAssetBase<string>] = mockTokens[curr].address;
      return prev;
    }, defaultTokenList);
    const addressProvider = await getMarketAddressController();

    const fallbackOracle = await deployMockPriceOracle(verify);
    await waitForTx(await fallbackOracle.setEthUsdPrice(MockUsdPriceInWei));
    await setInitialAssetPricesInOracle(AllAssetsInitialPrices, mockTokensAddress, fallbackOracle);

    const mockAggregators = await deployAllMockAggregators(AllAssetsInitialPrices, verify);

    const allTokenAddresses = getAllTokenAddresses(mockTokens);
    const allAggregatorsAddresses = getAllAggregatorsAddresses(mockAggregators);

    const [tokens, aggregators] = getTokenAggregatorPairs(allTokenAddresses, allAggregatorsAddresses);

    const oracle = await deployOracleRouter(
      [addressProvider.address, tokens, aggregators, fallbackOracle.address, await getOrCreateWethAddress(poolConfig)],
      verify
    );
    await addressProvider.setAddress(AccessFlags.PRICE_ORACLE, oracle.address);

    const lendingRateOracle = await deployLendingRateOracle([addressProvider.address], verify);

    const deployer = await getFirstSigner();
    await addressProvider.grantRoles(deployer.address, AccessFlags.LENDING_RATE_ADMIN);

    const { USD, ...tokensAddressesWithoutUsd } = allTokenAddresses;
    const allReservesAddresses = {
      ...tokensAddressesWithoutUsd,
    };
    await setInitialMarketRatesInRatesOracleByHelper(LendingRateOracleRates, allReservesAddresses, lendingRateOracle);

    await addressProvider.setAddress(AccessFlags.LENDING_RATE_ORACLE, lendingRateOracle.address);
  });
