/* global ethers task */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("dotenv").config();
const { deployContracts } = require("./scripts/deploy");
const {
	MXV_DIAMOND_CUT_FACET,
	MXV_DIAMOND_LOUPE_FACET,
	MXV_DIAMOND_ADDRESS,
	MXV_OWNERSHIP_FACET,
	MUSIXVERSE_FACET_ADDRESS,
	MUSIXVERSE_GETTERS_FACET_ADDRESS,
	MUSIXVERSE_SETTERS_FACET_ADDRESS,
} = require("./contract_addresses");

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

task("verify-contracts", "Verify smart contracts", async (taskArgs, hre) => {
	try {
		await hre.run("verify:verify", {
			address: MXV_DIAMOND_CUT_FACET,
			constructorArguments: [],
		});
	} catch (error) {
		console.log(error);
	}

	try {
		await hre.run("verify:verify", {
			address: MXV_DIAMOND_LOUPE_FACET,
			constructorArguments: [],
		});
	} catch (error) {
		console.log(error);
	}

	try {
		await hre.run("verify:verify", {
			address: MXV_OWNERSHIP_FACET,
			constructorArguments: [],
		});
	} catch (error) {
		console.log(error);
	}

	try {
		await hre.run("verify:verify", {
			address: MUSIXVERSE_FACET_ADDRESS,
			constructorArguments: ["https://ipfs.moralis.io:2053/ipfs/", "https://www.musixverse.com/contract-metadata-uri"],
		});
	} catch (error) {
		console.log(error);
	}

	try {
		await hre.run("verify:verify", {
			address: MUSIXVERSE_GETTERS_FACET_ADDRESS,
			constructorArguments: [],
		});
	} catch (error) {
		console.log(error);
	}

	try {
		await hre.run("verify:verify", {
			address: MUSIXVERSE_SETTERS_FACET_ADDRESS,
			constructorArguments: [],
		});
	} catch (error) {
		console.log(error);
	}
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
