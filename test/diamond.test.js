const { getSelectors, FacetCutAction, removeSelectors, findAddressPositionInFacets } = require("../scripts/libraries/diamond.js");
const { deployMusixverseDiamond } = require("../scripts/test_deploy.js");
const { assert } = require("chai");

describe("MusixverseDiamond Tests", async function () {
	let diamondAddress;
	let diamondCutFacet;
	let diamondLoupeFacet;
	let ownershipFacet;
	let tx;
	let receipt;
	let result;
	const facetAddresses = [];

	before(async function () {
		diamondAddress = await deployMusixverseDiamond();
		diamondCutFacet = await ethers.getContractAt("DiamondCutFacet", diamondAddress);
		diamondLoupeFacet = await ethers.getContractAt("DiamondLoupeFacet", diamondAddress);
		ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
	});

	it("should have three facets -- call to facetAddresses function", async () => {
		for (const address of await diamondLoupeFacet.facetAddresses()) {
			facetAddresses.push(address);
		}
		assert.equal(facetAddresses.length, 3);
	});

	it("facets should have the right function selectors -- call to facetFunctionSelectors function", async () => {
		let selectors = getSelectors(diamondCutFacet);
		result = await diamondLoupeFacet.facetFunctionSelectors(facetAddresses[0]);
		assert.sameMembers(result, selectors);
		selectors = getSelectors(diamondLoupeFacet);
		result = await diamondLoupeFacet.facetFunctionSelectors(facetAddresses[1]);
		assert.sameMembers(result, selectors);
		selectors = getSelectors(ownershipFacet);
		result = await diamondLoupeFacet.facetFunctionSelectors(facetAddresses[2]);
		assert.sameMembers(result, selectors);
	});

	it("selectors should be associated to facets correctly -- multiple calls to facetAddress function", async () => {
		assert.equal(facetAddresses[0], await diamondLoupeFacet.facetAddress("0x1f931c1c"));
		assert.equal(facetAddresses[1], await diamondLoupeFacet.facetAddress("0xcdffacc6"));
		assert.equal(facetAddresses[1], await diamondLoupeFacet.facetAddress("0x01ffc9a7"));
		assert.equal(facetAddresses[2], await diamondLoupeFacet.facetAddress("0xf2fde38b"));
	});

	it("should add MusixverseFacet functions", async () => {
		const LibMusixverse = await ethers.getContractFactory("LibMusixverse");
		const libMXV = await LibMusixverse.deploy();
		await libMXV.deployed();

		const MusixverseFacet = await ethers.getContractFactory("MusixverseFacet", {
			libraries: {
				LibMusixverse: libMXV.address,
			},
		});
		const musixverseFacet = await MusixverseFacet.deploy(
			"https://gateway.musixverse.com/ipfs/",
			"https://www.musixverse.com/contract-metadata-uri"
		);
		await musixverseFacet.deployed();
		facetAddresses.push(musixverseFacet.address);

		const selectors = getSelectors(musixverseFacet).remove(["supportsInterface(bytes4)"]);
		tx = await diamondCutFacet.diamondCut(
			[
				{
					facetAddress: musixverseFacet.address,
					action: FacetCutAction.Add,
					functionSelectors: selectors,
				},
			],
			ethers.constants.AddressZero,
			"0x",
			{ gasLimit: 800000 }
		);
		receipt = await tx.wait();
		if (!receipt.status) {
			throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
		}

		result = await diamondLoupeFacet.facetFunctionSelectors(musixverseFacet.address);
		assert.sameMembers(result, selectors);
	});

	it("should test function call", async () => {
		const musixverseFacet = await ethers.getContractAt("MusixverseFacet", diamondAddress);
		await musixverseFacet.pause();
	});

	it("should replace supportsInterface function", async () => {
		const LibMusixverse = await ethers.getContractFactory("LibMusixverse");
		const libMXV = await LibMusixverse.deploy();
		await libMXV.deployed();

		const MusixverseFacet = await ethers.getContractFactory("MusixverseFacet", {
			libraries: {
				LibMusixverse: libMXV.address,
			},
		});
		const selectors = getSelectors(MusixverseFacet).get(["supportsInterface(bytes4)"]);
		const musixverseFacetAddress = facetAddresses[3];
		tx = await diamondCutFacet.diamondCut(
			[
				{
					facetAddress: musixverseFacetAddress,
					action: FacetCutAction.Replace,
					functionSelectors: selectors,
				},
			],
			ethers.constants.AddressZero,
			"0x",
			{ gasLimit: 800000 }
		);
		receipt = await tx.wait();
		if (!receipt.status) {
			throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
		}
	});

	it("should add MusixverseGettersFacet functions", async () => {
		const MusixverseGettersFacet = await ethers.getContractFactory("MusixverseGettersFacet");
		const musixverseGettersFacet = await MusixverseGettersFacet.deploy();
		await musixverseGettersFacet.deployed();
		facetAddresses.push(musixverseGettersFacet.address);
		const selectors = getSelectors(musixverseGettersFacet);
		tx = await diamondCutFacet.diamondCut(
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
		receipt = await tx.wait();
		if (!receipt.status) {
			throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
		}
		result = await diamondLoupeFacet.facetFunctionSelectors(musixverseGettersFacet.address);
		assert.sameMembers(result, selectors);
	});

	it("should remove some MusixverseGettersFacet functions", async () => {
		const musixverseGettersFacet = await ethers.getContractAt("MusixverseGettersFacet", diamondAddress);
		const functionsToKeep = ["name()", "symbol()", "baseURI()"];
		const selectors = getSelectors(musixverseGettersFacet).remove(functionsToKeep);
		tx = await diamondCutFacet.diamondCut(
			[
				{
					facetAddress: ethers.constants.AddressZero,
					action: FacetCutAction.Remove,
					functionSelectors: selectors,
				},
			],
			ethers.constants.AddressZero,
			"0x",
			{ gasLimit: 800000 }
		);
		receipt = await tx.wait();
		if (!receipt.status) {
			throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
		}
		result = await diamondLoupeFacet.facetFunctionSelectors(facetAddresses[4]);
		assert.sameMembers(result, getSelectors(musixverseGettersFacet).get(functionsToKeep));
	});

	it("should remove all functions and facets except 'diamondCut' and 'facets'", async () => {
		let selectors = [];
		let facets = await diamondLoupeFacet.facets();
		for (let i = 0; i < facets.length; i++) {
			selectors.push(...facets[i].functionSelectors);
		}
		selectors = removeSelectors(selectors, ["facets()", "diamondCut(tuple(address,uint8,bytes4[])[],address,bytes)"]);
		tx = await diamondCutFacet.diamondCut(
			[
				{
					facetAddress: ethers.constants.AddressZero,
					action: FacetCutAction.Remove,
					functionSelectors: selectors,
				},
			],
			ethers.constants.AddressZero,
			"0x",
			{ gasLimit: 800000 }
		);
		receipt = await tx.wait();
		if (!receipt.status) {
			throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
		}
		facets = await diamondLoupeFacet.facets();
		assert.equal(facets.length, 2);
		assert.equal(facets[0][0], facetAddresses[0]);
		assert.sameMembers(facets[0][1], ["0x1f931c1c"]);
		assert.equal(facets[1][0], facetAddresses[1]);
		assert.sameMembers(facets[1][1], ["0x7a0ed627"]);
	});

	it("add most functions and facets", async () => {
		const diamondLoupeFacetSelectors = getSelectors(diamondLoupeFacet).remove(["supportsInterface(bytes4)"]);
		const LibMusixverse = await ethers.getContractFactory("LibMusixverse");
		const libMXV = await LibMusixverse.deploy();
		await libMXV.deployed();

		const MusixverseFacet = await ethers.getContractFactory("MusixverseFacet", {
			libraries: {
				LibMusixverse: libMXV.address,
			},
		});
		const MusixverseGettersFacet = await ethers.getContractFactory("MusixverseGettersFacet");
		// Any number of functions from any number of facets can be added/replaced/removed in a	single transaction
		const cut = [
			{
				facetAddress: facetAddresses[1],
				action: FacetCutAction.Add,
				functionSelectors: diamondLoupeFacetSelectors.remove(["facets()"]),
			},
			{
				facetAddress: facetAddresses[2],
				action: FacetCutAction.Add,
				functionSelectors: getSelectors(ownershipFacet),
			},
			{
				facetAddress: facetAddresses[3],
				action: FacetCutAction.Add,
				functionSelectors: getSelectors(MusixverseFacet),
			},
			{
				facetAddress: facetAddresses[4],
				action: FacetCutAction.Add,
				functionSelectors: getSelectors(MusixverseGettersFacet),
			},
		];
		tx = await diamondCutFacet.diamondCut(cut, ethers.constants.AddressZero, "0x", { gasLimit: 8000000 });
		receipt = await tx.wait();
		if (!receipt.status) {
			throw Error(`MusixverseDiamond upgrade failed: ${tx.hash}`);
		}
		const facets = await diamondLoupeFacet.facets();
		const _facetAddresses = await diamondLoupeFacet.facetAddresses();
		assert.equal(_facetAddresses.length, 5);
		assert.equal(facets.length, 5);
		assert.sameMembers(_facetAddresses, facetAddresses);
		assert.equal(facets[0][0], facetAddresses[0], "first facet");
		assert.equal(facets[1][0], facetAddresses[1], "second facet");
		assert.equal(facets[2][0], facetAddresses[2], "third facet");
		assert.equal(facets[3][0], facetAddresses[3], "fourth facet");
		assert.equal(facets[4][0], facetAddresses[4], "fifth facet");
		assert.sameMembers(facets[findAddressPositionInFacets(facetAddresses[0], facets)][1], getSelectors(diamondCutFacet));
		assert.sameMembers(facets[findAddressPositionInFacets(facetAddresses[1], facets)][1], diamondLoupeFacetSelectors);
		assert.sameMembers(facets[findAddressPositionInFacets(facetAddresses[2], facets)][1], getSelectors(ownershipFacet));
		assert.sameMembers(facets[findAddressPositionInFacets(facetAddresses[3], facets)][1], getSelectors(MusixverseFacet));
		assert.sameMembers(facets[findAddressPositionInFacets(facetAddresses[4], facets)][1], getSelectors(MusixverseGettersFacet));
	});
});
