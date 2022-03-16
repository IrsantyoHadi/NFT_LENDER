import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployNFT: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log('Deploying NFT');
  const dappsNFT = await deploy('DapsNFT', {
    from: deployer,
    args: [1111, 11],
    log: true,
  });
  log(`Deployed NFT to address ${dappsNFT.address}`);
};

export default deployNFT;
deployNFT.tags = ['all', 'NFT'];
