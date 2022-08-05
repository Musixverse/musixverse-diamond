// scripts/upgrade_mxv.js
const { ethers, upgrades } = require("hardhat");

const PROXY_ADDRESS = "";

async function main() {
	const MusixverseLib = await ethers.getContractFactory("MusixverseLib");
	const mxvLib = await MusixverseLib.deploy();

	const MusixverseContractV2 = await hre.ethers.getContractFactory("MusixverseV1", {
		libraries: {
			MusixverseLib: mxvLib.address,
		},
	});
	console.log("Upgrading Musixverse...");
	const mxv = await upgrades.upgradeProxy(
		PROXY_ADDRESS,
		MusixverseContractV2,
		["https://gateway.moralisipfs.com/ipfs/", "https://www.musixverse.com/contract-metadata-uri"],
		{ initializer: "initialize" }
	);
	console.log("Musixverse upgraded successfully.");

	console.log("Deployed library address:", mxvLib.address);
	console.log("Deployed contract address:", await upgrades.erc1967.getImplementationAddress(mxv.address));
	console.log("Deployed proxy address:", mxv.address);
}

main();
