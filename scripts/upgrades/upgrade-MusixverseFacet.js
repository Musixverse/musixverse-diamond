/* global ethers */
/* eslint prefer-const: "off" */

const { MXV_DIAMOND_ADDRESS } = require("../../contract_addresses");
const { getSelectors, FacetCutAction } = require("../libraries/diamond.js");

async function upgradeMusixverseFacet() {
	const LibMusixverse = await ethers.getContractFactory("LibMusixverse");
	const libMXV = await LibMusixverse.deploy();
	await libMXV.deployed();
	const MusixverseFacet = await ethers.getContractFactory("MusixverseFacet", {
		libraries: {
			LibMusixverse: libMXV.address,
		},
	});
	const musixverseFacet = await MusixverseFacet.deploy("https://ipfs.moralis.io:2053/ipfs/", "https://www.musixverse.com/contract-metadata-uri");
	await musixverseFacet.deployed();
	console.log(`\tMusixverseFacet deployed: ${musixverseFacet.address}`);

	const selectors = getSelectors(musixverseFacet).remove(["supportsInterface(bytes4)"]);
	const diamondCut = await ethers.getContractAt("IDiamondCut", MXV_DIAMOND_ADDRESS);

	const functionCall = musixverseFacet.interface.encodeFunctionData("__Musixverse_init_unchained", [
		"https://ipfs.moralis.io:2053/ipfs/",
		"https://www.musixverse.com/contract-metadata-uri",
	]);

	const tx = await diamondCut.diamondCut(
		[
			{
				facetAddress: musixverseFacet.address,
				action: FacetCutAction.Replace,
				functionSelectors: selectors,
			},
		],
		musixverseFacet.address,
		functionCall
	);
	console.log("\tMusixverseFacet cut tx:", tx.hash);
	const receipt = await tx.wait();
	if (!receipt.status) {
		throw Error(`MusixverseFacet upgrade failed: ${tx.hash}`);
	}
	console.log("\tCompleted MusixverseFacet diamond cut.\n");
}

if (require.main === module) {
	upgrade()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});
}

module.exports = { upgradeMusixverseFacet };
