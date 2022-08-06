/* global ethers task */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("dotenv").config();
const { deployContracts } = require("./scripts/deploy");

task("accounts", "Prints the list of accounts", async () => {
	const accounts = await ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

task("deploy", "Deploy smart contracts", async (taskArgs, hre) => {
	await deployContracts();
	// await hre.run("verify:verify", {
	//     address: mxv.address,
	//     constructorArguments: [],
	// });
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	solidity: "0.8.4",
	settings: {
		optimizer: {
			enabled: true,
			runs: 200,
		},
		contractSizer: {
			alphaSort: true,
			disambiguatePaths: false,
			runOnCompile: true,
		},
	},
	networks: {
		hardhat: {
			gas: 12000000,
			blockGasLimit: 210000000,
			// allowUnlimitedContractSize: true,
			timeout: 1800000,
		},
		mumbai: {
			url: "https://polygon-mumbai.g.alchemy.com/v2/8qorAGwStqgObuxITbYVAD3T2BI1jC36",
			accounts: [process.env.PRIVATE_KEY],
			gas: 12000000,
			gasPrice: 35000000000,
			blockGasLimit: 210000000,
			timeout: 1800000,
		},
	},
	etherscan: {
		apiKey: process.env.POLYGONSCAN_API_KEY,
	},
};
