import {
  ethers,
  deployments,
  getUnnamedAccounts,
  getNamedAccounts,
} from 'hardhat';
import { Contract } from 'ethers';
import { toWei } from '../../utils';
import { transferSand } from '../utils';

export const setupCollectionCatalystMigrations = deployments.createFixture(async () => {
  await deployments.fixture();
  const { collectionCatalystMigrationsAdmin } = await getNamedAccounts();
  const users = await getUnnamedAccounts();
  const user0 = users[0];

  const collectionCatalystMigrationsContract: Contract = await ethers.getContract(
    'CollectionCatalystMigrations'
  );
  const oldCatalystRegistry: Contract = await ethers.getContract(
    'OldCatalystRegistry'
  );
  const oldCatalystMinter: Contract = await ethers.getContract(
    'OldCatalystMinter'
  );
  const assetAttributesRegistry: Contract = await ethers.getContract(
    'AssetAttributesRegistry'
  );

  const collectionCatalystMigrationsContractAsAdmin = await collectionCatalystMigrationsContract.connect(
    ethers.provider.getSigner(collectionCatalystMigrationsAdmin)
  );
  const oldCatalystMinterAsUser0 = await oldCatalystMinter.connect(
    ethers.provider.getSigner(user0)
  );
  const collectionCatalystMigrationsContractAsUser0 = await collectionCatalystMigrationsContract.connect(
    ethers.provider.getSigner(user0)
  );
  return {
    assetAttributesRegistry,
    oldCatalystMinterAsUser0,
    collectionCatalystMigrationsContractAsAdmin,
    collectionCatalystMigrationsContractAsUser0,
    oldCatalystRegistry,
    oldCatalystMinter,
    user0
  }
});

export const setupUser = async (user: string) => {
  const { gemMinter, catalystMinter } = await getNamedAccounts();

  const gem: Contract = await ethers.getContract("OldGems");
  const catalyst = await ethers.getContract(`OldCatalysts`);

  const gemAsGemMinter = await gem.connect(
    ethers.provider.getSigner(gemMinter)
  );
  const catalystAsCatalystMinter = await catalyst.connect(ethers.provider.getSigner(catalystMinter));
  const sandContract = await ethers.getContract("Sand");
  await transferSand(sandContract, user, toWei(4));
  for (let i = 0; i < 5; i++) {
    await gemAsGemMinter.mint(user, i, 50);
  }
  for (let i = 0; i < 4; i++) {
    await catalystAsCatalystMinter.mint(user, i, 20);
  }
};
