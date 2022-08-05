const { ethers, upgrades } = require("hardhat");

async function main() {
	const MusixverseLib = await ethers.getContractFactory("MusixverseLib");
	const mxvLib = await MusixverseLib.deploy();

	const MusixverseContract = await hre.ethers.getContractFactory("MusixverseV1", {
		libraries: {
			MusixverseLib: mxvLib.address,
		},
	});
	console.log("Deploying Musixverse...");
	const mxv = await upgrades.deployProxy(
		MusixverseContract,
		["https://gateway.moralisipfs.com/ipfs/", "https://www.musixverse.com/contract-metadata-uri"],
		{
			initializer: "initialize",
		}
	);
	await mxv.deployed();

	console.log("Deployed library address:", mxvLib.address);
	console.log("Deployed contract address:", await upgrades.erc1967.getImplementationAddress(mxv.address));
	console.log("Deployed proxy address:", mxv.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
