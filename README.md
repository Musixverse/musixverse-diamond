# Musixverse Diamond

The **Musixverse Diamond** is an implementation that leverages the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535).

The standard loupe functions have been gas-optimized in this implementation and can be called in on-chain transactions.

**Note:** The loupe functions in DiamondLoupeFacet.sol MUST be added to the diamond and are required by the EIP-2535 Diamonds standard.

## Installation

1. Clone this repo:
```console
git clone https://github.com/Musixverse/musixverse-diamond.git
```

2. Install NPM packages:
```console
cd musixverse-diamond
npm install
```

## Run tests:

To run all test files-
```console
npx hardhat test
```

To run a single test file-
```console
npx hardhat test test/musixverse.test.js
```

## Check the size of contracts

```console
npx hardhat size-contracts
```

## Deployment

Create a `.env` file in the `.env.example` file format.
Add your secrets and api keys.

```console
npx hardhat run scripts/deploy.js
```

or

```console
npx hardhat deploy --network <NETWORK_NAME>
```

**Things to keep in mind during development & deployment-**

1. Storage Collision

https://forum.openzeppelin.com/t/openzeppelin-upgrades-step-by-step-tutorial-for-hardhat/3580/4

2. Constructor functions don't work in Facets

https://eip2535diamonds.substack.com/p/constructor-functions-dont-work-in?s=w

### How the scripts/deploy.js script works

1. DiamondCutFacet is deployed.
1. The diamond is deployed, passing as arguments to the diamond constructor the owner address of the diamond and the DiamondCutFacet address. DiamondCutFacet has the `diamondCut` external function which is used to upgrade the diamond to add more functions.
1. The `DiamondInit` contract is deployed. This contains an `init` function which is called on the first diamond upgrade to initialize state of some state variables. Information on how the `diamondCut` function works is here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
1. Facets are deployed.
1. The diamond is upgraded. The `diamondCut` function is used to add functions from facets to the diamond. In addition the `diamondCut` function calls the `init` function from the `DiamondInit` contract using `delegatecall` to initialize state variables.


## Verifying source code on block explorer

```console
npx hardhat verify CONTRACT_ADDR --network mumbai
```


## Upgrading the diamond

Check the `scripts/deploy.js` and or the `test/diamond.test.js` file for examples of upgrades.

Note that any number of functions from any number of facets can be added/replaced/removed on a diamond in a single transaction. In addition an initialization function can be executed in the same transaction as an upgrade to initialize any state variables required for an upgrade. This 'everything done in a single transaction' capability ensures a diamond maintains a correct and consistent state during upgrades.

## Facet Information

The `contracts/shared/MusixverseDiamond.sol` file shows the implementation of Musixverse Diamond.

The `contracts/shared/facets/DiamondCutFacet.sol` file shows how to implement the `diamondCut` external function.

The `contracts/shared/facets/DiamondLoupeFacet.sol` file shows how to implement the four standard loupe functions.

The `contracts/shared/libraries/LibDiamond.sol` file shows how to implement Diamond Storage and the `diamondCut` internal function.

The `scripts/deploy.js` file has functions that show how to deploy the diamond.

The `test/diamond.test.js` file gives tests for the `diamondCut` function and the Diamond Loupe functions.

## Steps to deploy locally-

1. Start a local node

`npx hardhat node`

2. Open a new terminal and deploy the smart contract on the localhost network

`npx hardhat run --network localhost scripts/deploy_upgradeable_mxv.js`

3. As general rule, you can target any network configured in the hardhat.config.js

`npx hardhat run --network <your-network> scripts/deploy_upgradeable_mxv.js`

4. For upgrading

`npx hardhat run --network localhost scripts/upgrade_mxv_to_v2.js`

## Hardhat console testing

`npx hardhat console --network localhost`

`const Musixverse = await ethers.getContractFactory('MusixverseV1');`

`const mxv = await Musixverse.attach('0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9');`

`(await mxv.getMusixverseMain()).toString();`

`await mxv.setMusixverseMain("0x159507b2b3829791fAB794581D2aC074F3596013");`

`mxv.mintTrackNFT(1, 10, ["QmQQqbwJqzQqwfnjtsP1FwZQcYKroBiA5ppcEBc1fvPSTt"], ['0x159507b2b3829791fAB794581D2aC074F3596013'], [100], 5, true);`