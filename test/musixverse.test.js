// test/Musixverse.js
// Load dependencies
const { getSelectors, FacetCutAction, removeSelectors, findAddressPositionInFacets } = require("../scripts/libraries/diamond.js");
const {
	deployMusixverseDiamond,
	deployMusixverseFacet,
	deployMusixverseGettersFacet,
	deployMusixverseSettersFacet,
} = require("../scripts/test_deploy.js");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { mintTrack, mint3TokensOfTrack } = require("./utils/helpers");

// Start test block
describe("Musixverse Tests", function () {
	let diamondAddress;
	let musixverseFacetAddress;
	let musixverseGettersFacetAddress;
	let musixverseSettersFacetAddress;
	let diamondCutFacet;
	let diamondLoupeFacet;
	let ownershipFacet;
	let musixverseFacet;
	let musixverseGettersFacet;
	let musixverseSettersFacet;

	before(async function () {
		diamondAddress = await deployMusixverseDiamond();
		musixverseFacetAddress = await deployMusixverseFacet();
		musixverseGettersFacetAddress = await deployMusixverseGettersFacet();
		musixverseSettersFacetAddress = await deployMusixverseSettersFacet();
		diamondCutFacet = await ethers.getContractAt("DiamondCutFacet", diamondAddress);
		diamondLoupeFacet = await ethers.getContractAt("DiamondLoupeFacet", diamondAddress);
		ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
		musixverseFacet = await ethers.getContractAt("MusixverseFacet", diamondAddress);
		musixverseGettersFacet = await ethers.getContractAt("MusixverseGettersFacet", diamondAddress);
		musixverseSettersFacet = await ethers.getContractAt("MusixverseSettersFacet", diamondAddress);
	});

	describe("Contract Deployment and Ownership", function () {
		it("Should return contract deployer's address", async function () {
			// Test if the returned value is the same one
			// Note that we need to use strings to compare the 256 bit integers
			const [owner] = await ethers.getSigners();
			expect((await ownershipFacet.owner()).toString()).to.equal(owner.address);
			console.log("\tContract Deployer:", owner.address);
			console.log("\tDeployed Diamond Address:", diamondAddress);
			console.log("\tDeployed MusixverseFacet Address:", musixverseFacetAddress);
			console.log("\tDeployed MusixverseGettersFacet Address:", musixverseGettersFacetAddress);
		});

		it("Should have a contract name", async () => {
			const name = await musixverseGettersFacet.name();
			expect(name.toString()).to.equal("Musixverse");
		});

		it("Should have a contract symbol", async () => {
			const symbol = await musixverseGettersFacet.symbol();
			expect(symbol.toString()).to.equal("MXV");
		});

		it("Should not transfer ownership of the contract when called by some address other than the owner", async function () {
			const [owner, addr1, addr2] = await ethers.getSigners();
			await expect(ownershipFacet.connect(addr1).transferOwnership(addr2.address)).to.be.revertedWith("LibDiamond: Must be contract owner");
		});

		it("Should transfer ownership of the contract when called by the owner", async function () {
			const [owner, addr1] = await ethers.getSigners();
			const tx = await ownershipFacet.connect(owner).transferOwnership(addr1.address);
			await tx.wait();
			expect((await ownershipFacet.owner()).toString()).to.equal(addr1.address);
		});

		it("Should transfer back the ownership of contract when called by the new owner", async function () {
			const [owner, addr1] = await ethers.getSigners();
			const tx = await ownershipFacet.connect(addr1).transferOwnership(owner.address);
			await tx.wait();
			expect((await ownershipFacet.owner()).toString()).to.equal(owner.address);
		});
	});

	describe("Contract URI", function () {
		it("Should return correct contract metadata URI", async function () {
			expect((await musixverseGettersFacet.contractURI()).toString()).to.equal("https://www.musixverse.com/contract-metadata-uri");
		});

		it("Should update and return the correct empty contract URI", async function () {
			await musixverseSettersFacet.updateContractURI("");
			expect((await musixverseGettersFacet.contractURI()).toString()).to.equal("");
		});
	});

	describe("Mint track NFT", function () {
		it("Should batch mint an NFT", async function () {
			const [owner, addr1] = await ethers.getSigners();
			await mintTrack(musixverseFacet, addr1);

			var balance = await musixverseFacet.balanceOf(addr1.address, 1);
			expect(1).to.equal(Number(balance.toString()));

			await mintTrack(musixverseFacet, addr1);
			balance = await musixverseFacet.balanceOf(addr1.address, 2);
			expect(1).to.equal(Number(balance.toString()));
		});

		it("Should batch mint 3 NFTs", async function () {
			const [owner, addr1, addr2] = await ethers.getSigners();
			await mint3TokensOfTrack(musixverseFacet, addr1, addr2);

			var balance = await musixverseFacet.balanceOf(addr1.address, 1);
			expect(1).to.equal(Number(balance.toString()));
			balance = await musixverseFacet.balanceOf(addr1.address, 2);
			expect(1).to.equal(Number(balance.toString()));
			balance = await musixverseFacet.balanceOf(addr1.address, 3);
			expect(1).to.equal(Number(balance.toString()));
			balance = await musixverseFacet.balanceOf(addr1.address, 4);
			expect(1).to.equal(Number(balance.toString()));
			balance = await musixverseFacet.balanceOf(addr1.address, 5);
			expect(1).to.equal(Number(balance.toString()));
			// Since only 2+3=5 NFTs were minted
			balance = await musixverseFacet.balanceOf(addr1.address, 6);
			expect(0).to.equal(Number(balance.toString()));
		});

		it("Should get correct token URI", async function () {
			const [owner, addr1, addr2] = await ethers.getSigners();
			await mintTrack(musixverseFacet, addr1);
			expect((await musixverseFacet.uri(1)).toString()).to.equal(
				(await musixverseGettersFacet.baseURI()) + "QmQQqbwJqzQqwfnjtsP1FwZQcYKroBiA5ppcEBc1fvPSTt"
			);

			await mint3TokensOfTrack(musixverseFacet, addr1, addr2);
			expect((await musixverseFacet.uri(3)).toString()).to.equal(
				(await musixverseGettersFacet.baseURI()) + "Qmbijgmi1APqH2UaMVPkwoAKyNiBEHUjap54s3MAifKta6"
			);
		});
	});

	describe("Royalties", function () {
		it("Should return royalties for a token", async function () {
			const [owner, addr1, addr2] = await ethers.getSigners();
			await mint3TokensOfTrack(musixverseFacet, addr1, addr2);

			const royalties = await musixverseFacet.getRoyaltyInfo(5);
			expect((await royalties[0].recipient).toString()).to.equal(addr1.address);
			expect((await royalties[1].recipient).toString()).to.equal(addr2.address);
			expect((await royalties[0].percentage).toString()).to.equal("80");
			expect((await royalties[1].percentage).toString()).to.equal("20");
		});
	});

	describe("Update Price", async () => {
		it("Should update the price of a trackNFT", async () => {
			// Success: Current owner updates the price
			const [owner, addr1, addr2] = await ethers.getSigners();
			await mintTrack(musixverseFacet, addr1);

			const _tokenId = 1;
			var _trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			expect(10).to.equal(Number(ethers.utils.formatEther(_trackNFT.price)));

			await musixverseFacet.connect(addr1).updatePrice(_tokenId, ethers.utils.parseEther("100"));

			_trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			expect(100).to.equal(Number(ethers.utils.formatEther(_trackNFT.price)));

			// Failure: Tries to update the price of a trackNFT that does not exist- Must have valid id
			expect(musixverseFacet.connect(addr1).updatePrice(2, ethers.utils.parseEther("100"))).to.be.revertedWith(
				"LibMusixverse: Invalid tokenId"
			);
			// Failure: An address other than the current owner tries to update the price of the NFT
			expect(musixverseFacet.connect(addr2).updatePrice(1, ethers.utils.parseEther("100"))).to.be.revertedWith(
				"LibMusixverse: Must be token owner to call this function"
			);
		});
	});

	describe("Toggle onSale attribute", async () => {
		it("Should toggle the onSale attribute", async () => {
			const [owner, addr1, addr2] = await ethers.getSigners();
			await mintTrack(musixverseFacet, addr1);

			// Success: Current owner toggles the onSale attribute
			const _tokenId = 1;
			var _trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			expect(true).to.equal(_trackNFT.onSale);

			await musixverseFacet.connect(addr1).toggleOnSale(1);

			_trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			expect(false).to.equal(_trackNFT.onSale);

			// Failure: Tries to toggle a trackNFT that does not exist- Must have valid id
			expect(musixverseFacet.connect(addr1).toggleOnSale(2)).to.be.revertedWith("LibMusixverse: Invalid tokenId");
			// Failure: An address other than the current owner tries to toggle the onSale attribute
			expect(musixverseFacet.connect(addr2).toggleOnSale(1)).to.be.revertedWith("LibMusixverse: Must be token owner to call this function");
		});
	});

	describe("Purchase NFT", function () {
		it("Should purchase an NFT from artist and then subsequent owner", async function () {
			const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
			var balance;

			balance = await ethers.provider.getBalance(musixverseFacet.address);
			console.log("\n\tBalance of contract:", ethers.utils.formatEther(balance));

			balance = await ethers.provider.getBalance(addr1.address);
			console.log("\n\tInitial balance of artist 1 (" + addr1.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr2.address);
			console.log("\tInitial balance of artist 2 (" + addr2.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr3.address);
			console.log("\tInitial balance of buyer (" + addr3.address + ") :", ethers.utils.formatEther(balance));

			console.log("\n\t-----------------------------------------------------------------------------------------------------------------");
			console.log("\tMinting 3 copies of NFT...");

			// addr1 and addr2 are the collaborators. addr1 is the minter
			await mint3TokensOfTrack(musixverseFacet, addr1, addr2);

			console.log("\t-----------------------------------------------------------------------------------------------------------------\n");

			balance = await ethers.provider.getBalance(addr1.address);
			console.log("\tBalance of artist 1 after minting NFTs:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr2.address);
			console.log("\tBalance of artist 2 after minting NFTs:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr3.address);
			console.log("\tBalance of buyer after minting NFTs:", ethers.utils.formatEther(balance));

			const _tokenId = 4;
			console.log("\n\tOwner of NFT id", _tokenId, "before purchase:", (await musixverseFacet.ownerOf(_tokenId)).toString());

			console.log("\n\t-----------------------------------------------------------------------------------------------------------------\n");

			var _trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			await musixverseFacet.connect(addr3).purchaseTrackNFT(_tokenId, { value: _trackNFT.price, gasLimit: 2000000 });

			balance = await ethers.provider.getBalance(musixverseFacet.address);
			console.log("\tBalance of contract after NFT purchase:", ethers.utils.formatEther(balance));

			balance = await ethers.provider.getBalance(addr1.address);
			console.log("\n\tBalance of artist 1 after NFT purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr2.address);
			console.log("\tBalance of artist 2 after NFT purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr3.address);
			console.log("\tBalance of buyer after NFT purchase:", ethers.utils.formatEther(balance));

			console.log("\n\tOwner of NFT id", _tokenId, "after purchase:", (await musixverseFacet.ownerOf(_tokenId)).toString());

			// Update NFT Price
			console.log("\n\t-----------------------------------------------------------------------------------------------------------------");
			console.log("\tUpdating price from 100 to 1000...");
			await musixverseFacet.connect(addr3).updatePrice(_tokenId, ethers.utils.parseEther("1000"));
			console.log("\t-----------------------------------------------------------------------------------------------------------------\n");

			balance = await ethers.provider.getBalance(musixverseFacet.address);
			console.log("\tBalance of contract:", ethers.utils.formatEther(balance));

			balance = await ethers.provider.getBalance(addr1.address);
			console.log("\n\tBalance of artist 1 (" + addr1.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr2.address);
			console.log("\tBalance of artist 2 (" + addr2.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr3.address);
			console.log("\tBalance of seller (" + addr3.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr4.address);
			console.log("\tBalance of buyer (" + addr4.address + ") :", ethers.utils.formatEther(balance));

			console.log("\n\tOwner of NFT id", _tokenId, "before 2nd purchase:", (await musixverseFacet.ownerOf(_tokenId)).toString());

			console.log("\n\t-----------------------------------------------------------------------------------------------------------------");

			_trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			await musixverseFacet.connect(addr4).purchaseTrackNFT(_tokenId, { value: _trackNFT.price });

			balance = await ethers.provider.getBalance(musixverseFacet.address);
			console.log("\n\tBalance of contract after 2nd purchase:", ethers.utils.formatEther(balance));

			balance = await ethers.provider.getBalance(addr1.address);
			console.log("\n\tInitial balance of artist 1 after 2nd purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr2.address);
			console.log("\tInitial balance of artist 2 after 2nd purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr3.address);
			console.log("\tInitial balance of seller after 2nd purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr4.address);
			console.log("\tInitial balance of buyer after 2nd purchase:", ethers.utils.formatEther(balance));

			console.log("\n\tOwner of NFT id", _tokenId, "after 2nd purchase:", (await musixverseFacet.ownerOf(_tokenId)).toString());
		});
	});

	describe("Purchase Referred NFT", function () {
		it("Should purchase an NFT that a collector shares/refers", async function () {
			const [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8] = await ethers.getSigners();
			var balance;

			balance = await ethers.provider.getBalance(musixverseFacet.address);
			console.log("\n\tBalance of contract:", ethers.utils.formatEther(balance));

			balance = await ethers.provider.getBalance(addr5.address);
			console.log("\n\tInitial balance of artist 1 (" + addr5.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr6.address);
			console.log("\tInitial balance of artist 2 (" + addr6.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr7.address);
			console.log("\tInitial balance of sharer/referrer (" + addr7.address + ") :", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr8.address);
			console.log("\tInitial balance of buyer (" + addr8.address + ") :", ethers.utils.formatEther(balance));

			console.log("\n\t-----------------------------------------------------------------------------------------------------------------");
			console.log("\tMinting 3 copies of NFT...");

			// addr5 and addr6 are the collaborators. addr5 is the minter
			await mint3TokensOfTrack(musixverseFacet, addr5, addr6);

			console.log("\t-----------------------------------------------------------------------------------------------------------------\n");

			balance = await ethers.provider.getBalance(addr5.address);
			console.log("\tBalance of artist 1 after minting NFTs:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr6.address);
			console.log("\tBalance of artist 2 after minting NFTs:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr7.address);
			console.log("\tBalance of sharer/referrer after minting NFTs:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr8.address);
			console.log("\tBalance of buyer after minting NFTs:", ethers.utils.formatEther(balance));

			const _tokenId = 20;
			console.log("\n\tOwner of NFT id", _tokenId, "before purchase:", (await musixverseFacet.ownerOf(_tokenId)).toString());

			console.log("\n\t-----------------------------------------------------------------------------------------------------------------\n");

			var _trackNFT = await musixverseGettersFacet.trackNFTs(_tokenId);
			await musixverseFacet.connect(addr8).purchaseReferredTrackNFT(_tokenId, addr7.address, { value: _trackNFT.price, gasLimit: 2000000 });

			balance = await ethers.provider.getBalance(musixverseFacet.address);
			console.log("\tBalance of contract after NFT purchase:", ethers.utils.formatEther(balance));

			balance = await ethers.provider.getBalance(addr5.address);
			console.log("\n\tBalance of artist 1 after NFT purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr6.address);
			console.log("\tBalance of artist 2 after NFT purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr7.address);
			console.log("\tBalance of sharer/referrer after NFT purchase:", ethers.utils.formatEther(balance));
			balance = await ethers.provider.getBalance(addr8.address);
			console.log("\tBalance of buyer after NFT purchase:", ethers.utils.formatEther(balance));

			console.log("\n\tOwner of NFT id", _tokenId, "after purchase:", (await musixverseFacet.ownerOf(_tokenId)).toString());
		});
	});

	describe("Update Platform Fee Percentage", async () => {
		it("Should update the platform fee percentage", async () => {
			const feePercentage = await musixverseGettersFacet.PLATFORM_FEE_PERCENTAGE();
			assert.equal(feePercentage, 1);

			await musixverseSettersFacet.updatePlatformFeePercentage(5);

			const updatedFeePercentage = await musixverseGettersFacet.PLATFORM_FEE_PERCENTAGE();
			assert.equal(updatedFeePercentage, 5);
		});

		it("Should not update platform fee percentage if not called by owner", async () => {
			const [owner, addr1] = await ethers.getSigners();
			// Failure: An address other than the contract owner tries to update the platform fee percentage
			expect(musixverseSettersFacet.connect(addr1).updatePlatformFeePercentage(3)).to.be.revertedWith("LibDiamond: Must be contract owner");

			const feePercentage = await musixverseGettersFacet.PLATFORM_FEE_PERCENTAGE();
			assert.equal(feePercentage, 5);
		});

		it("Should revert the platform fee percentage back to 1", async () => {
			await musixverseSettersFacet.updatePlatformFeePercentage(1);

			const updatedFeePercentage = await musixverseGettersFacet.PLATFORM_FEE_PERCENTAGE();
			assert.equal(updatedFeePercentage, 1);
		});
	});
});
