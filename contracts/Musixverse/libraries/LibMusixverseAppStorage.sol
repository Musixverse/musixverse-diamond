// contracts/Musixverse/libraries/LibMusixverseAppStorage.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

/// @dev Note: This contract is meant to declare any storage and is append-only. DO NOT modify old variables!

import { Counters } from "./LibCounters.sol";

/***********************************|
|    Variables, structs, mappings   |
|__________________________________*/

struct TrackNftCreationData {
	uint16 amount;
	uint256 price;
	string URIHash;
	string unlockableContentURIHash;
	address[] collaborators;
	uint16[] percentageContributions;
	uint16 resaleRoyaltyPercentage;
	bool onSale;
	uint256 unlockTimestamp;
}

struct Track {
	string metadataHash;
	string unlockableContentHash;
	address artistAddress;
	uint16 resaleRoyaltyPercentage;
	uint256 unlockTimestamp;
}

struct Token {
	uint256 trackId;
	uint256 price;
	bool onSale;
	bool soldOnce;
}

struct RoyaltyInfo {
	address payable recipient;
	uint256 percentage;
}

struct MusixverseAppStorage {
	string name;
	string symbol;
	string contractURI;
	string baseURI;
	uint8 PLATFORM_FEE_PERCENTAGE;
	address payable PLATFORM_ADDRESS;
	// Cut percentage relative to PLATFORM_FEE_PERCENTAGE
	uint8 REFERRAL_CUT;
	Counters.Counter mxvLatestTokenId;
	Counters.Counter totalTracks;
	// Mapping from track ID to track data
	mapping(uint256 => Track) trackNFTs;
	// Mapping from token ID to token data
	mapping(uint256 => Token) tokens;
	// Mapping from token ID to owner address
	mapping(uint256 => address) owners;
	// Mapping from track ID to royalty info
	mapping(uint256 => RoyaltyInfo[]) royalties;
	// Mapping from token ID to comment
	mapping(uint256 => string) commentWall;
}

library LibMusixverseAppStorage {
	function diamondStorage() internal pure returns (MusixverseAppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}

	function abs(int256 x) internal pure returns (uint256) {
		return uint256(x >= 0 ? x : -x);
	}
}
