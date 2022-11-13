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
import { MusixverseFacet } from "./MusixverseFacet.sol";

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

	function getToken(uint256 tokenId) external view returns (Token memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.tokens[tokenId];
	}

	function getCommentOnToken(uint256 tokenId) external view virtual returns (string memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.commentWall[tokenId];
	}

	function unlockableContentUri(uint256 mxvTokenId) public view virtual returns (string memory) {
		require(mxvTokenId > 0 && mxvTokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		// Require that nft owner is calling the function
		require(MusixverseFacet(s.PLATFORM_ADDRESS).ownerOf(mxvTokenId) == msg.sender, "Must be token owner to call this function");
		return string(abi.encodePacked(s.baseURI, s.trackNFTs[s.tokens[mxvTokenId].trackId].unlockableContentHash));
	}

	// @notice Called with the token id to determine how much royalty is owed and to whom
	// @param tokenId - the NFT asset queried for royalty information
	// @return RoyaltyInfo[] - an array of type RoyaltyInfo having objects with the following fields: recipient, percentage
	// @info recipient - address of who should be sent the royalty payment
	// @info percentage - the royalty payment percentage
	function getRoyaltyInfo(uint256 tokenId) public view virtual returns (RoyaltyInfo[] memory) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.royalties[s.tokens[tokenId].trackId];
	}
}
