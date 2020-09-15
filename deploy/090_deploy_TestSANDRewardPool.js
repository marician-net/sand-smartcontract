const {guard} = require("../lib");
const {Contract} = require("ethers");
const {ethers} = require("@nomiclabs/buidler");
const IUniswapV2Factory = require("@uniswap/v2-core/build/IUniswapV2Factory.json");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deploy, log} = deployments;
  const {deployer} = await getNamedAccounts();

  // createPair to generate Rinkeby Uniswap SAND-ETH pair
  // UniswapV2Factory is deployed at 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f on Mainnet and Rinkeby
  const uniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"; // Rinkeby

  const chainId = await getChainId();

  if (chainId === "4") {
    const uniswapV2Factory = new Contract(
      uniswapV2FactoryAddress,
      IUniswapV2Factory.abi,
      ethers.provider.getSigner(deployer)
    );

    const pairCreatorAsDeployer = uniswapV2Factory.connect(ethers.provider.getSigner(deployer));

    const receipt = await pairCreatorAsDeployer.functions
      .createPair("0xCc933a862fc15379E441F2A16Cb943D385a4695f", "0xc778417E063141139Fce010982780140Aa0cD5Ab", {
        gasLimit: 8000000,
      }) //.then((tx) => tx.wait()); // makes deployment crash

    // Rinkeby SAND token address, Rinkeby WETH token address

    console.log("pair", receipt);

    const events = receipt.events;
    const pairCreationEvent = events.find(event => event.event === "PairCreated");
    const pairAddress = pairCreationEvent.args[2];

    if (pairAddress) {
      log("Rinkeby SAND address: 0xCc933a862fc15379E441F2A16Cb943D385a4695f");
      log("Rinkeby WETH address: 0xc778417E063141139Fce010982780140Aa0cD5Ab");
      log(`Rinkeby UniswapV2 SAND-ETH Pair Contract Address: ${pairAddress}`);

      await deploy("TestSANDRewardPool", {
        from: deployer,
        args: [pairAddress],
        log: true,
      });
    }
  }
};

module.exports.skip = guard(["1", "314159", "4"], "TestSANDRewardPool"); // Remove "TestSANDRewardPool"
module.exports.tags = ["TestSANDRewardPool"];
