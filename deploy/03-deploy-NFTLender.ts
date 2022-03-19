import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const deployNFTLender: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const dapsToken = await get('DapsToken');

  log('Deploying NFT Lender');
  const NFTLender = await deploy('ERC721Lender', {
    from: deployer,
    args: [dapsToken.address],
    log: true,
  });
  log(`Deployed NFT  Lender to address ${NFTLender.address}`);

  log('Check Payment Token Address');

  const nftLender = await ethers.getContract('ERC721Lender', deployer);

  const paymentAddress = await nftLender.paymentTokenAddress();
  log(`Payment Address set to ${paymentAddress}`);
};

export default deployNFTLender;
deployNFTLender.tags = ['all', 'NFTLender'];
