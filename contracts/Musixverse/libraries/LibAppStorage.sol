// contracts/MusixverseEternalStorage.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/
// This contract is meant to declare any storage and is append-only. DO NOT modify old variables!

import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/***********************************|
|    Variables, structs, mappings   |
|__________________________________*/

struct TrackNFT {
	uint256 price;
	address artistAddress;
	uint16 resaleRoyaltyPercentage;
	bool onSale;
	bool soldOnce;
	uint256 unlockTimestamp;
}

struct RoyaltyInfo {
	address payable recipient;
	uint256 percentage;
}

struct AppStorage {
	string name;
	string symbol;
	string contractURI;
	string baseURI;
	uint8 PLATFORM_FEE_PERCENTAGE;
	address PLATFORM_ADDRESS;
	Counters.Counter mxvLatestTokenId;
	Counters.Counter totalTracks;
	mapping(uint256 => string) mxvTokenHashes;
	// Mapping from token ID to owner address
	mapping(uint256 => address) _owners;
	mapping(uint256 => TrackNFT) trackNFTs;
	mapping(uint256 => RoyaltyInfo[]) royalties;
}

library LibAppStorage {
	function diamondStorage() internal pure returns (AppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}

	function abs(int256 x) internal pure returns (uint256) {
		return uint256(x >= 0 ? x : -x);
	}
}

contract Modifiers {
	// modifier onlyTokenOwner(uint256 _tokenId) {
	// 	require(LibMeta.msgSender() == s.aavegotchis[_tokenId].owner, "LibAppStorage: Only aavegotchi owner can call this function");
	// 	_;
	// }

	// modifier onlyUnlocked(uint256 _tokenId) {
	// 	require(s.aavegotchis[_tokenId].locked == false, "LibAppStorage: Only callable on unlocked Aavegotchis");
	// 	_;
	// }

	modifier onlyOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}

	/***********************************|
    |              Events               |
    |__________________________________*/

	event TokenCreated(uint256 trackId, uint256 tokenId, uint256 price, uint256 localTokenId);

	event TrackMinted(uint256 trackId, uint256 maxTokenId, uint256 price, string URIHash);

	event TokenPurchased(uint256 tokenId, address previousOwner, address newOwner, uint256 price);

	event TokenPriceUpdated(uint256 tokenId, uint256 oldPrice, uint256 newPrice);

	event TokenOnSaleUpdated(uint256 tokenId, bool onSale);
}
