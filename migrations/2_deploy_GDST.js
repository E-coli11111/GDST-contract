// migrations/NN_deploy_upgradeable_box.js
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const GDST = artifacts.require('GDST');
const Admin = artifacts.require('Admin');

module.exports = async function (deployer) {
  const instance = await deployProxy(GDST, [], { deployer });
  console.log('Deployed', instance.address);
  await deployer.deploy(Admin, instance.address);
};