const { ethers } = require("hardhat");

const mintTrack = async function (musixverseFacet) {
	const [owner, addr1] = await ethers.getSigners();
	const numberOfCopies = 1;
	const price = ethers.utils.parseEther("10");
	const metadataURIHash = "QmQQqbwJqzQqwfnjtsP1FwZQcYKroBiA5ppcEBc1fvPSTt";
	const collaborators = [addr1.address];
	const percentageContributions = [100];
	const resaleRoyaltyPercentage = 5;
	const onSale = true;
	// JavaScript shows timestamp in milliseconds, but Solidity does it in seconds. Converting timestamp in milliseconds to seconds
	const unlockTimestamp = Math.round(Date.now() / 1000);
	await musixverseFacet
		.connect(addr1)
		.mintTrackNFT(
			numberOfCopies,
			price,
			metadataURIHash,
			collaborators,
			percentageContributions,
			resaleRoyaltyPercentage,
			onSale,
			unlockTimestamp
		);
};

const mint3TokensOfTrack = async function (musixverseFacet) {
	const [owner, addr1, addr2] = await ethers.getSigners();
	const numberOfCopies = 3;
	const price = ethers.utils.parseEther("100");
	const metadataURIHash = "Qmbijgmi1APqH2UaMVPkwoAKyNiBEHUjap54s3MAifKta6";
	const collaborators = [addr1.address, addr2.address];
	const percentageContributions = [80, 20];
	const resaleRoyaltyPercentage = 5;
	const onSale = true;
	const unlockTimestamp = Math.round(Date.now() / 1000);
	await musixverseFacet
		.connect(addr1)
		.mintTrackNFT(
			numberOfCopies,
			price,
			metadataURIHash,
			collaborators,
			percentageContributions,
			resaleRoyaltyPercentage,
			onSale,
			unlockTimestamp
		);
};

module.exports = { mintTrack, mint3TokensOfTrack };
