const { ethers } = require("hardhat");

const mintTrack = async function (musixverseFacet, artist1) {
	const numberOfCopies = 1;
	const price = ethers.utils.parseEther("10");
	const metadataURIHash = "QmWSrUnaQCJArHSHEmHjZ8QMCyijUvXwtJNxcXqHoy3GUy";
	const unlockableContentURIHash = "QmTUE2Jwg9aDEQzRZZB2Bw44PDLMSv7URBNZ1ohwKm5RDj";
	const collaborators = [artist1.address];
	const percentageContributions = [100];
	const resaleRoyaltyPercentage = 5;
	const onSale = true;
	// JavaScript shows timestamp in milliseconds, but Solidity does it in seconds. Converting timestamp in milliseconds to seconds
	const unlockTimestamp = Math.round(Date.now() / 1000);
	return await musixverseFacet
		.connect(artist1)
		.mintTrackNFT([
			numberOfCopies,
			price,
			metadataURIHash,
			unlockableContentURIHash,
			collaborators,
			percentageContributions,
			resaleRoyaltyPercentage,
			onSale,
			unlockTimestamp,
		]);
};

const mint3TokensOfTrack = async function (musixverseFacet, artist1, artist2) {
	const numberOfCopies = 3; // 80 working, 2500 working with tokenCreated event emitted, UNLIMITED (65535) with lazy minting voucher
	const price = ethers.utils.parseEther("100");
	const metadataURIHash = "Qmbijgmi1APqH2UaMVPkwoAKyNiBEHUjap54s3MAifKta6";
	const unlockableContentURIHash = "QmZgB7PyESb9nZQSbTKPXwtk6YYmTFsvSM3qDX5Bxhisqp";
	const collaborators = [artist1.address, artist2.address];
	const percentageContributions = [80, 20];
	const resaleRoyaltyPercentage = 5;
	const onSale = true;
	const unlockTimestamp = Math.round(Date.now() / 1000);
	return await musixverseFacet
		.connect(artist1)
		.mintTrackNFT([
			numberOfCopies,
			price,
			metadataURIHash,
			unlockableContentURIHash,
			collaborators,
			percentageContributions,
			resaleRoyaltyPercentage,
			onSale,
			unlockTimestamp,
		]);
};

module.exports = { mintTrack, mint3TokensOfTrack };
