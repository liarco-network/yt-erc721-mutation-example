import { ethers } from "hardhat";

async function main() {
  const GenesisToken = await ethers.getContractFactory("GenesisToken");
  const genesisToken = await GenesisToken.deploy();

  await genesisToken.deployed();

  console.log("GenesisToken deployed to:", genesisToken.address);

  const MutationToken = await ethers.getContractFactory("MutationToken");
  const mutationToken = await MutationToken.deploy(genesisToken.address, "ipfs://__CID__/");

  await mutationToken.deployed();

  console.log("MutationToken deployed to:", mutationToken.address);

  const MutatedToken = await ethers.getContractFactory("MutatedToken");
  const mutatedToken = await MutatedToken.deploy(genesisToken.address, mutationToken.address);

  await mutationToken.deployed();

  console.log("MutatedToken deployed to:", mutatedToken.address);

  await mutationToken.setMutatedContractAddress(mutatedToken.address);

  console.log("MutatedToken contract connected to MutationToken contract");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
