// contracts/Musixverse/libraries/LibMusixverse.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.4;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Counters } from "./LibCounters.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { LibMusixverseAppStorage, MusixverseAppStorage, TrackNftCreationData, Track, Token, RoyaltyInfo } from "./LibMusixverseAppStorage.sol";
import { MusixverseFacet } from "../facets/MusixverseFacet.sol";

library LibMusixverse {
	using SafeMath for uint256;
	using Counters for Counters.Counter;

	function checkForMinting(TrackNftCreationData calldata data) public pure {
		require(data.amount > 0, "No tokens to mint");
		require(data.price > 0, "Price must be greater than 0");
		require(bytes(data.URIHash).length != 0, "URIHash must be present");
		require(
			data.collaborators.length == data.percentageContributions.length,
			"collaborators and percentageContributions must be the same length"
		);
		require(data.resaleRoyaltyPercentage >= 0, "resaleRoyaltyPercentage must be greater than or equal to 0");
		checkForRoyalties(data.collaborators, data.percentageContributions);
	}

	function checkForRoyalties(address[] calldata collaborators, uint16[] calldata percentageContributions) public pure {
		require(collaborators.length == percentageContributions.length, "collaborators and percentageContributions must be the same length");

		for (uint256 i = 0; i < collaborators.length; i++) {
			require(collaborators[i] != address(0x0), "Recipient should be present");
			require(percentageContributions[i] > 0, "Royalty percentage should be positive");
		}
	}

	function checkForSale(
		Track memory trackNFT,
		Token memory token,
		address prevOwner
	) public view {
		isPastUnlockTimestamp(trackNFT);
		// Require that the song is available for sale
		require(token.onSale, "Token not available for sale");
		// Require that buyer is not the seller
		require(prevOwner != msg.sender, "You cannot purchase your own song");
		// Require that there is enough matic provided for the transaction
		require(msg.value >= token.price, "Not enough value for the transaction");
	}

	function setRoyalties(
		uint256 trackId,
		address[] calldata collaborators,
		uint16[] calldata percentageContributions,
		mapping(uint256 => RoyaltyInfo[]) storage royalties
	) public {
		for (uint256 i = 0; i < collaborators.length; i++) {
			royalties[trackId].push(RoyaltyInfo(payable(collaborators[i]), percentageContributions[i]));
		}
	}

	function purchaseToken(
		uint256 tokenId,
		address payable referrer,
		mapping(uint256 => Track) storage trackNFTs,
		mapping(uint256 => Token) storage tokens,
		Counters.Counter storage mxvLatestTokenId
	) public {
		MusixverseAppStorage storage s = LibMusixverseAppStorage.diamondStorage();
		isValidTokenId(tokenId, mxvLatestTokenId);
		// Fetch the token
		Token memory _token = tokens[tokenId];
		// Fetch the trackNFT
		Track memory _trackNFT = trackNFTs[tokens[tokenId].trackId];
		address _prevOwner = MusixverseFacet(s.PLATFORM_ADDRESS).ownerOf(tokenId);
		// Check that the trackNFT is available for sale
		checkForSale(_trackNFT, _token, _prevOwner);
		// Transfer amounts
		_distributeFunds(tokenId, referrer, _trackNFT, _token, _prevOwner, tokens);
	}

	function _distributeFunds(
		uint256 tokenId,
		address payable referrer,
		Track memory trackNFT,
		Token memory token,
		address prevOwner,
		mapping(uint256 => Token) storage tokens
	) internal {
		MusixverseAppStorage storage s = LibMusixverseAppStorage.diamondStorage();
		if (referrer == address(0)) {
			// Deduct the platform fee
			uint256 _platformFee = ((msg.value).mul(s.PLATFORM_FEE_PERCENTAGE)).div(100);
			Address.sendValue(s.PLATFORM_ADDRESS, _platformFee);

			if (token.soldOnce) {
				// Pay the artists _royaltyPercentage% of the transaction amount as royalty
				uint256 _royaltyAmount = ((msg.value).mul(trackNFT.resaleRoyaltyPercentage)).div(100);
				_distributeRoyalties(s.PLATFORM_ADDRESS, tokenId, _royaltyAmount);
				// Pay the seller by sending remaining amount
				uint256 _value = ((msg.value).mul(100 - (s.PLATFORM_FEE_PERCENTAGE + trackNFT.resaleRoyaltyPercentage))).div(100);
				payable(prevOwner).transfer(_value);
			} else {
				// Pay the remaining transaction amount to the artists
				uint256 _value = ((msg.value).mul(100 - s.PLATFORM_FEE_PERCENTAGE)).div(100);
				_distributeRoyalties(s.PLATFORM_ADDRESS, tokenId, _value);
			}
		} else {
			// Deduct platform fee and referral fee
			uint256 _platformFee = ((msg.value).mul(s.PLATFORM_FEE_PERCENTAGE)).div(100);
			uint256 _referralFee = ((_platformFee).mul(s.REFERRAL_CUT)).div(100);
			Address.sendValue(referrer, _referralFee);
			Address.sendValue(s.PLATFORM_ADDRESS, _platformFee - _referralFee);

			if (token.soldOnce) {
				// Pay the artists _royaltyPercentage% of the transaction amount as royalty
				uint256 _royaltyAmount = ((msg.value).mul(trackNFT.resaleRoyaltyPercentage)).div(100);
				_distributeRoyalties(s.PLATFORM_ADDRESS, tokenId, _royaltyAmount);
				// Pay the seller by sending remaining amount
				uint256 _value = ((msg.value).mul(100 - (s.PLATFORM_FEE_PERCENTAGE + trackNFT.resaleRoyaltyPercentage))).div(100);
				payable(prevOwner).transfer(_value);
			} else {
				// Pay the remaining transaction amount to the artists
				uint256 _value = ((msg.value).mul(100 - s.PLATFORM_FEE_PERCENTAGE)).div(100);
				_distributeRoyalties(s.PLATFORM_ADDRESS, tokenId, _value);
			}
		}

		if (!token.soldOnce) {
			// Set soldOnce to true
			token.soldOnce = true;
			// Update songNFT
			tokens[tokenId] = token;
		}
	}

	function _distributeRoyalties(
		address payable PLATFORM_ADDRESS,
		uint256 tokenId,
		uint256 royaltyAmount
	) internal {
		RoyaltyInfo[] memory _royalties = MusixverseFacet(PLATFORM_ADDRESS).getRoyaltyInfo(tokenId);
		for (uint256 i = 0; i < _royalties.length; i++) {
			uint256 _value = (royaltyAmount).mul(_royalties[i].percentage).div(100);
			payable(_royalties[i].recipient).transfer(_value);
		}
	}

	function updateTokenPrice(
		address payable PLATFORM_ADDRESS,
		uint256 tokenId,
		mapping(uint256 => Token) storage tokens,
		uint256 newPrice,
		Counters.Counter storage mxvLatestTokenId
	) public returns (uint256, uint256) {
		isValidCallByNFTOwner(PLATFORM_ADDRESS, tokenId, mxvLatestTokenId);
		// Fetch the song
		Token storage _token = tokens[tokenId];
		// Old price
		uint256 _oldPrice = _token.price;
		// Edit the price
		_token.price = newPrice;
		// Update the song
		tokens[tokenId] = _token;

		return (_oldPrice, newPrice);
	}

	function toggleOnSaleAttribute(
		address payable PLATFORM_ADDRESS,
		uint256 tokenId,
		mapping(uint256 => Track) storage trackNFTs,
		mapping(uint256 => Token) storage tokens,
		Counters.Counter storage mxvLatestTokenId
	) public returns (bool) {
		isValidCallByNFTOwner(PLATFORM_ADDRESS, tokenId, mxvLatestTokenId);
		// Fetch the track
		Track memory _trackNFT = trackNFTs[tokens[tokenId].trackId];
		Token storage _token = tokens[tokenId];
		isPastUnlockTimestamp(_trackNFT);
		// Toggle onSale attribute
		if (_token.onSale == true) {
			_token.onSale = false;
		} else if (_token.onSale == false) {
			_token.onSale = true;
		}
		// Update the token
		tokens[tokenId] = _token;

		return _token.onSale;
	}

	function updateComment(
		address payable PLATFORM_ADDRESS,
		uint256 tokenId,
		string memory comment,
		mapping(uint256 => string) storage commentWall,
		Counters.Counter storage mxvLatestTokenId
	) public returns (string memory) {
		isValidCallByNFTOwner(PLATFORM_ADDRESS, tokenId, mxvLatestTokenId);
		string memory _previousComment = commentWall[tokenId];
		// Update the comment
		commentWall[tokenId] = comment;

		return _previousComment;
	}

	/* ---------------------- Modifiers converted to functions --------------------- */
	function isValidTokenId(uint256 tokenId, Counters.Counter storage mxvLatestTokenId) public view {
		// Require that the token id is valid
		require(tokenId > 0 && tokenId <= mxvLatestTokenId.current(), "LibMusixverse: Token DNE");
	}

	function isNFTOwner(address payable PLATFORM_ADDRESS, uint256 tokenId) public view {
		// Require that nft owner is calling the function
		require(MusixverseFacet(PLATFORM_ADDRESS).ownerOf(tokenId) == msg.sender, "LibMusixverse: Must be token owner to call this function");
	}

	function isValidCallByNFTOwner(
		address payable PLATFORM_ADDRESS,
		uint256 tokenId,
		Counters.Counter storage mxvLatestTokenId
	) public view {
		isValidTokenId(tokenId, mxvLatestTokenId);
		isNFTOwner(PLATFORM_ADDRESS, tokenId);
	}

	function isPastUnlockTimestamp(Track memory trackNFT) public view {
		// Require that current time is past unlockTimestamp
		require(block.timestamp > trackNFT.unlockTimestamp, "LibMusixverse: Only callable on unlocked tokens");
	}
}
