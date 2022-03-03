const { ethers, upgrades } = require("hardhat");

async function main() {
  const AnemonethV1 = await ethers.getContractFactory("AnemonethV1");
  const proxy = await upgrades.deployProxy(AnemonethV1, [1, 2]);
  await proxy.deployed();

  console.log(proxy.address);
}

main();