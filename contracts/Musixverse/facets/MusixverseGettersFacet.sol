// contracts/Musixverse/facets/MusixverseGettersFacet.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { Counters } from "../libraries/LibCounters.sol";
import { MusixverseAppStorage, Track, Token, RoyaltyInfo } from "../libraries/LibMusixverseAppStorage.sol";
import { MusixverseEternalStorage } from "../common/MusixverseEternalStorage.sol";

contract MusixverseGettersFacet is MusixverseEternalStorage {
	using Counters for Counters.Counter;

	/// @notice Return the universal name of the NFT
	function name() external view returns (string memory) {
		return s.name;
	}

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory) {
		return s.symbol;
	}

	function contractURI() external view returns (string memory) {
		return s.contractURI;
	}

	function baseURI() external view returns (string memory) {
		return s.baseURI;
	}

	function PLATFORM_FEE_PERCENTAGE() external view returns (uint8) {
		return s.PLATFORM_FEE_PERCENTAGE;
	}

	function PLATFORM_ADDRESS() external view returns (address) {
		return s.PLATFORM_ADDRESS;
	}

	function mxvLatestTokenId() external view returns (Counters.Counter memory) {
		return s.mxvLatestTokenId;
	}

	function totalTracks() external view returns (Counters.Counter memory) {
		return s.totalTracks;
	}

	function trackNFTs(uint256 tokenId) external view returns (Track memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.trackNFTs[s.tokens[tokenId].trackId];
	}

	function getTrack(uint256 trackId) external view returns (Track memory) {
		require(trackId > 0 && trackId <= s.totalTracks.current(), "Track DNE");
		return s.trackNFTs[trackId];
	}

	function getToken(uint256 tokenId) external view returns (Token memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.tokens[tokenId];
	}

	function royalties(uint256 tokenId) external view returns (RoyaltyInfo[] memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.royalties[s.tokens[tokenId].trackId];
	}

	function getCommentOnToken(uint256 tokenId) external view virtual returns (string memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.commentWall[tokenId];
	}
}
