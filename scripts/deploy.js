/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");
let musixverseDiamondAddress;

async function deployMusixverseDiamond() {
	const accounts = await ethers.getSigners();
	const contractOwner = accounts[0];

	// deploy DiamondCutFacet
	const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
	const diamondCutFacet = await DiamondCutFacet.deploy();
	await diamondCutFacet.deployed();
	console.log("\n\tDiamondCutFacet deployed:", diamondCutFacet.address);

	// deploy MusixverseDiamond
	const MusixverseDiamond = await ethers.getContractFactory("MusixverseDiamond");
	const diamond = await MusixverseDiamond.deploy(contractOwner.address, diamondCutFacet.address);
	await diamond.deployed();
	console.log("\tMusixverseDiamond deployed:", diamond.address);
	musixverseDiamondAddress = diamond.address;

	// deploy DiamondInit
	// DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
	// Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
	const DiamondInit = await ethers.getContractFactory("DiamondInit");
	const diamondInit = await DiamondInit.deploy();
	await diamondInit.deployed();
	console.log("\tDiamondInit deployed:", diamondInit.address);

	// deploy facets
	console.log("\n\tDeploying facets...\n");
	const FacetNames = ["DiamondLoupeFacet", "OwnershipFacet"];
	const cut = [];
	for (const FacetName of FacetNames) {
		const Facet = await ethers.getContractFactory(FacetName);
		const facet = await Facet.deploy();
		await facet.deployed();
		console.log(`\t${FacetName} deployed: ${facet.address}`);
		cut.push({
			facetAddress: facet.address,
			action: FacetCutAction.Add,
			functionSelectors: getSelectors(facet),
		});
	}

	// upgrade diamond with facets
	// console.log("MusixverseDiamond Cut:", cut);
	const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
	let tx;
	let receipt;
	// call to init function
	let functionCall = diamondInit.interface.encodeFunctionData("init");
	tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall);
	console.log("\tMusixverseDiamond cut tx:", tx.hash);
	receipt = await tx.wait();
	if (!receipt.status) {
		throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
	}
	console.log("\tCompleted diamond cut.\n");
	return diamond.address;
}

async function deployMusixverseFacet() {
	const LibMusixverse = await ethers.getContractFactory("LibMusixverse");
	const libMXV = await LibMusixverse.deploy();
	await libMXV.deployed();

	const MusixverseFacet = await ethers.getContractFactory("MusixverseFacet", {
		libraries: {
			LibMusixverse: libMXV.address,
		},
	});
	const musixverseFacet = await MusixverseFacet.deploy("https://gateway.moralisipfs.com/ipfs/", "https://www.musixverse.com/contract-metadata-uri");
	await musixverseFacet.deployed();
	console.log(`\tMusixverseFacet deployed: ${musixverseFacet.address}`);
	const selectors = getSelectors(musixverseFacet).remove(["supportsInterface(bytes4)"]);

	const diamondCut = await ethers.getContractAt("IDiamondCut", musixverseDiamondAddress);
	const functionCall = musixverseFacet.interface.encodeFunctionData("__Musixverse_init_unchained", [
		"https://gateway.moralisipfs.com/ipfs/",
		"https://www.musixverse.com/contract-metadata-uri",
	]);
	const tx = await diamondCut.diamondCut(
		[
			{
				facetAddress: musixverseFacet.address,
				action: FacetCutAction.Add,
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
	return musixverseFacet.address;
}

async function deployMusixverseGettersFacet() {
	const MusixverseGettersFacet = await ethers.getContractFactory("MusixverseGettersFacet");
	const musixverseGettersFacet = await MusixverseGettersFacet.deploy();
	await musixverseGettersFacet.deployed();
	console.log(`\tMusixverseGettersFacet deployed: ${musixverseGettersFacet.address}`);

	const selectors = getSelectors(musixverseGettersFacet);
	const diamondCut = await ethers.getContractAt("IDiamondCut", musixverseDiamondAddress);
	const tx = await diamondCut.diamondCut(
		[
			{
				facetAddress: musixverseGettersFacet.address,
				action: FacetCutAction.Add,
				functionSelectors: selectors,
			},
		],
		ethers.constants.AddressZero,
		"0x",
		{ gasLimit: 800000 }
	);
	console.log("\tMusixverseGettersFacet cut tx:", tx.hash);
	const receipt = await tx.wait();
	if (!receipt.status) {
		throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
	}
	console.log("\tCompleted MusixverseGettersFacet diamond cut.\n");
	return musixverseGettersFacet.address;
}

async function deployMusixverseSettersFacet() {
	const MusixverseSettersFacet = await ethers.getContractFactory("MusixverseSettersFacet");
	const musixverseSettersFacet = await MusixverseSettersFacet.deploy();
	await musixverseSettersFacet.deployed();
	console.log(`\tMusixverseSettersFacet deployed: ${musixverseSettersFacet.address}`);

	const selectors = getSelectors(musixverseSettersFacet);
	const diamondCut = await ethers.getContractAt("IDiamondCut", musixverseDiamondAddress);
	const tx = await diamondCut.diamondCut(
		[
			{
				facetAddress: musixverseSettersFacet.address,
				action: FacetCutAction.Add,
				functionSelectors: selectors,
			},
		],
		ethers.constants.AddressZero,
		"0x",
		{ gasLimit: 800000 }
	);
	console.log("\tMusixverseSettersFacet cut tx:", tx.hash);
	const receipt = await tx.wait();
	if (!receipt.status) {
		throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
	}
	console.log("\tCompleted MusixverseGettersFacet diamond cut.\n");
	return musixverseSettersFacet.address;
}

// We recommend this pattern to be able to use async/await everywhere and properly handle errors.
if (require.main === module) {
	deployMusixverseDiamond()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});
}

module.exports = { deployMusixverseDiamond, deployMusixverseFacet, deployMusixverseGettersFacet, deployMusixverseSettersFacet };
