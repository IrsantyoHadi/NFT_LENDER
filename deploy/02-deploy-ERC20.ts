import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployERC20: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log('Deploying Daps Token');
  const dapsToken = await deploy('DapsToken', {
    from: deployer,
    args: [],
    log: true,
  });
  log(`Deployed Daps Token to address ${dapsToken.address}`);
};

export default deployERC20;
deployERC20.tags = ['all', 'ERC20'];
