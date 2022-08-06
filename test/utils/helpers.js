const { ethers } = require("hardhat");

const mintTrack = async function (musixverseFacet, artist1) {
	const numberOfCopies = 1;
	const price = ethers.utils.parseEther("10");
	const metadataURIHash = "QmQQqbwJqzQqwfnjtsP1FwZQcYKroBiA5ppcEBc1fvPSTt";
	const collaborators = [artist1.address];
	const percentageContributions = [100];
	const resaleRoyaltyPercentage = 5;
	const onSale = true;
	// JavaScript shows timestamp in milliseconds, but Solidity does it in seconds. Converting timestamp in milliseconds to seconds
	const unlockTimestamp = Math.round(Date.now() / 1000);
	await musixverseFacet
		.connect(artist1)
		.mintTrackNFT([
			numberOfCopies,
			price,
			metadataURIHash,
			collaborators,
			percentageContributions,
			resaleRoyaltyPercentage,
			onSale,
			unlockTimestamp,
		]);
};

const mint3TokensOfTrack = async function (musixverseFacet, artist1, artist2) {
	const numberOfCopies = 3;
	const price = ethers.utils.parseEther("100");
	const metadataURIHash = "Qmbijgmi1APqH2UaMVPkwoAKyNiBEHUjap54s3MAifKta6";
	const collaborators = [artist1.address, artist2.address];
	const percentageContributions = [80, 20];
	const resaleRoyaltyPercentage = 5;
	const onSale = true;
	const unlockTimestamp = Math.round(Date.now() / 1000);
	await musixverseFacet
		.connect(artist1)
		.mintTrackNFT([
			numberOfCopies,
			price,
			metadataURIHash,
			collaborators,
			percentageContributions,
			resaleRoyaltyPercentage,
			onSale,
			unlockTimestamp,
		]);
};

module.exports = { mintTrack, mint3TokensOfTrack };
