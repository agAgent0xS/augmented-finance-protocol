import { task } from 'hardhat/config';
import { ConfigNames } from '../../helpers/configuration';
import {
  cleanupJsonDb,
  cleanupUiConfig,
  getFirstSigner,
  getTenderlyDashboardLink,
  printContracts,
} from '../../helpers/misc-utils';
import { usingTenderly } from '../../helpers/tenderly-utils';
import { exit } from 'process';
import { BigNumber } from 'ethers';

task('augmented:mainnet', 'Deploy enviroment')
  .addFlag('incremental', 'Incremental deployment')
  .addFlag('secure', 'Renounce credentials on errors')
  .addFlag('strict', 'Fail on warnings')
  .addFlag('reuse', 'Allow reuse of a price oracle')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ incremental, secure, reuse, strict, verify }, DRE) => {
    const POOL_NAME = ConfigNames.Augmented;
    const MAINNET_FORK = process.env.MAINNET_FORK === 'true';
    await DRE.run('set-DRE');

    const deployer = await getFirstSigner();
    const startBalance: BigNumber = await deployer.getBalance();
    let spentOnPluck: BigNumber = BigNumber.from(0);

    let renounce = false;
    let success = false;

    try {
      await cleanupUiConfig();
      console.log('Deployer start balance: ', startBalance.div(1e12).toNumber() / 1e6);

      if (incremental) {
        console.log('======================================================================');
        console.log('======================================================================');
        console.log('====================    ATTN! INCREMENTAL MODE    ====================');
        console.log('======================================================================');
        console.log(`=========== Delete 'deployed-contracts.json' to start anew ===========`);
        console.log('======================================================================');
        console.log('======================================================================');
      } else {
        await cleanupJsonDb(DRE.network.name);
        renounce = secure;
      }

      console.log('Deployment started\n');
      const trackVerify = true;

      console.log('01. Deploy address provider registry');
      await DRE.run('full:deploy-address-provider', { pool: POOL_NAME, verify: trackVerify });

      console.log('02. Deploy oracles');
      await DRE.run('full:deploy-oracles', { pool: POOL_NAME, verify: trackVerify, reuse: reuse });

      console.log('03. Deploy lending pool');
      await DRE.run('full:deploy-lending-pool', { pool: POOL_NAME, verify: trackVerify });

      console.log('04. Deploy WETH Gateway');
      await DRE.run('full-deploy-weth-gateway', { pool: POOL_NAME, verify: trackVerify });

      console.log('05. Deploy auxiliary contracts');
      await DRE.run('full:aux-contracts', { pool: POOL_NAME, verify: trackVerify });

      console.log('06. Initialize lending pool');
      await DRE.run('full:initialize-lending-pool', { pool: POOL_NAME, verify: trackVerify });

      console.log('07. Deploy StakeConfigurator');
      await DRE.run('full:deploy-stake-configurator', { pool: POOL_NAME, verify: trackVerify });

      console.log('08. Deploy and initialize stake tokens');
      await DRE.run('full:init-stake-tokens', { pool: POOL_NAME, verify: trackVerify });

      console.log('09. Deploy reward contracts and AGF token');
      await DRE.run('full:deploy-reward-contracts', { pool: POOL_NAME, verify: trackVerify });

      console.log('10. Deploy reward pools');
      await DRE.run('full:init-reward-pools', { pool: POOL_NAME, verify: trackVerify });

      console.log('11. Access test');
      await DRE.run('full:access-test', { pool: POOL_NAME });

      console.log('12. Smoke test');
      await DRE.run('full:smoke-test', { pool: POOL_NAME });

      const balanceBeforePluck = await deployer.getBalance();
      if (MAINNET_FORK) {
        console.log('Pluck');
        await DRE.run('dev:pluck-tokens', { pool: POOL_NAME });
      }
      spentOnPluck = balanceBeforePluck.sub(await deployer.getBalance());

      {
        const [entryMap, instanceCount, multiCount] = printContracts((await getFirstSigner()).address);

        let hasWarn = false;
        if (multiCount > 0) {
          console.error('WARNING: multi-deployed contract(s) detected');
          hasWarn = true;
        } else if (entryMap.size != instanceCount) {
          console.error('WARNING: unknown contract(s) detected');
          hasWarn = true;
        }

        entryMap.forEach((value, key, m) => {
          if (key.startsWith('Mock')) {
            console.error('WARNING: mock contract detected:', key);
            hasWarn = true;
          }
        });

        if (hasWarn && strict) {
          throw 'warnings are present';
        }
      }

      renounce = true;
      success = true;
    } catch (err) {
      if (usingTenderly()) {
        console.error('Check tx error:', getTenderlyDashboardLink());
      }
      console.error('\n=========================================================\nERROR:', err, '\n');
    }

    if (renounce || success) {
      try {
        console.log('99. Finalize');
        await DRE.run('full:deploy-finalize', { pool: POOL_NAME, register: success });
      } catch (err) {
        console.log('Error during finalization & renouncement');
        console.error(err);
      }
    }

    {
      const endBalance = await deployer.getBalance();
      console.log('======================================================================');
      console.log('Deployer end balance: ', endBalance.div(1e12).toNumber() / 1e6);
      console.log('Deploy expenses: ', startBalance.sub(endBalance).div(1e12).toNumber() / 1e6);
      const gasPrice = DRE.network.config.gasPrice;
      if (gasPrice != 'auto') {
        console.log(
          'Deploy gas     : ',
          startBalance.sub(endBalance).sub(spentOnPluck).div(gasPrice).toNumber(),
          '@',
          gasPrice / 1e9,
          ' gwei'
        );
      }
      console.log('======================================================================');
    }

    if (!success) {
      console.log('\nDeployment has failed');
      exit(1);
    }

    console.log('Write UI config');
    await DRE.run('full:write-ui-config', { pool: POOL_NAME });

    console.log('\nDeployment has finished');

    if (usingTenderly()) {
      const postDeployHead = (<any>DRE).tenderlyNetwork.getHead();
      const postDeployFork = (<any>DRE).tenderlyNetwork.getFork();
      console.log('Tenderly Info');
      console.log('- Head', postDeployHead);
      console.log('- Fork', postDeployFork);
    }

    if (verify) {
      console.log('N. Verify all contracts');
      await DRE.run('verify:verify-all-contracts', { pool: POOL_NAME });
    }
  });
