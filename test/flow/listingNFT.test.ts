import { DapsToken, DapsNFT, ERC721Lender } from '../../typechain-types';
import { deployments, ethers } from 'hardhat';
import { expect } from 'chai';

describe('Listing NFT', async () => {
  let dapsToken: DapsToken;
  let dapsNFT: DapsNFT;
  let erc721Lender: ERC721Lender;

  beforeEach(async () => {
    await deployments.fixture(['all']);
    dapsToken = await ethers.getContract('DapsToken');
    dapsNFT = await ethers.getContract('DapsNFT');
    erc721Lender = await ethers.getContract('ERC721Lender');
  });

  const allowTransfer = async (acc: any, address: string, tokenId: number) => {
    dapsNFT.connect(acc).approve(address, tokenId);
  };

  it('should list NFT', async () => {
    let [_, acc1] = await ethers.getSigners();
    //mint nft
    const mintTx = await dapsNFT.connect(acc1).mint(2, '0x01');
    await mintTx.wait(1);
    console.log('MINT SUCCESS');

    //allow contract to do transfer NFT
    allowTransfer(acc1, erc721Lender.address, 0);

    //list nft
    const listTx = await erc721Lender.connect(acc1).listNFT(dapsNFT.address, 0, 1, 100, 10);
    await listTx.wait(1);

    const acc1NFTBalance = await dapsNFT.balanceOf(acc1.address);
    const contractNFTBalance = await dapsNFT.balanceOf(erc721Lender.address);

    expect(acc1NFTBalance).equal(1);
    expect(contractNFTBalance).equal(1);
  });
});
