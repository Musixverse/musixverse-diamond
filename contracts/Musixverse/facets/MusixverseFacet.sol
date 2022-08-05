// contracts/MusixverseFacet.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { AppStorage, Modifiers, TrackNFT, RoyaltyInfo } from "../libraries/LibAppStorage.sol";
import { AppStorageFacet } from "./AppStorageFacet.sol";
import { LibMusixverse } from "../libraries/LibMusixverse.sol";

contract MusixverseFacet is AppStorageFacet, ERC1155, Pausable, Modifiers {
	using SafeMath for uint256;
	using Counters for Counters.Counter;

	constructor(string memory baseURI_, string memory contractURI_) ERC1155(string(abi.encodePacked(baseURI_, "{id}"))) {
		__Musixverse_init_unchained(baseURI_, contractURI_);
	}

	function __Musixverse_init_unchained(string memory baseURI_, string memory contractURI_) public {
		s.name = "Musixverse";
		s.symbol = "MXV";
		s.PLATFORM_FEE_PERCENTAGE = 1;
		s.PLATFORM_ADDRESS = address(this);
		s.contractURI = contractURI_;
		s.baseURI = baseURI_;
		_setURI(string(abi.encodePacked(baseURI_, "{id}")));
	}

	function pause() public virtual whenNotPaused onlyOwner {
		super._pause();
	}

	function unpause() public virtual whenPaused onlyOwner {
		super._unpause();
	}

	function updateURI(string memory newURI) public onlyOwner {
		_setURI(newURI);
	}

	function updateContractMetadataURI(string memory newURI) public onlyOwner {
		s.contractURI = newURI;
	}

	function updateBaseURI(string memory newURI) public onlyOwner {
		s.baseURI = newURI;
	}

	// Overriding the uri function
	function uri(uint256 mxvTokenId) public view virtual override returns (string memory) {
		require(mxvTokenId > 0 && mxvTokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return string(abi.encodePacked(s.baseURI, s.mxvTokenHashes[mxvTokenId]));
	}

	function ownerOf(uint256 tokenId) public view returns (address) {
		require(s._owners[tokenId] != address(0), "Token DNE");
		return s._owners[tokenId];
	}

	function _setTokenUri(uint256 _tokenId, string memory _tokenURIHash) internal virtual {
		s.mxvTokenHashes[_tokenId] = _tokenURIHash;
	}

	function updatePlatformFeePercentage(uint8 newPlatformFeePercentage) public onlyOwner {
		s.PLATFORM_FEE_PERCENTAGE = newPlatformFeePercentage;
	}

	function mintTrackNFT(
		uint16 amount,
		uint256 price,
		string calldata URIHash,
		address[] calldata collaborators,
		uint16[] calldata percentageContributions,
		uint16 resaleRoyaltyPercentage,
		bool onSale,
		uint256 unlockTimestamp
	) external virtual whenNotPaused {
		LibMusixverse.checkForMinting(amount, price, URIHash, collaborators, percentageContributions, resaleRoyaltyPercentage);

		uint256[] memory _tokenIds = new uint256[](amount);
		uint256[] memory _tokenAmounts = new uint256[](amount);

		for (uint256 i = 0; i < amount; i++) {
			s.mxvLatestTokenId.increment();
			_tokenIds[i] = s.mxvLatestTokenId.current();
			_tokenAmounts[i] = 1;
			_setTokenUri(s.mxvLatestTokenId.current(), URIHash);
			LibMusixverse.setRoyalties(s.mxvLatestTokenId.current(), collaborators, percentageContributions, s.royalties);
			s._owners[s.mxvLatestTokenId.current()] = msg.sender;
			s.trackNFTs[s.mxvLatestTokenId.current()] = TrackNFT(price, msg.sender, resaleRoyaltyPercentage, onSale, false, unlockTimestamp);
		}
		_mintBatch(msg.sender, _tokenIds, _tokenAmounts, "");
		s.totalTracks.increment();

		for (uint256 i = 0; i < amount; i++) {
			emit TokenCreated(s.totalTracks.current(), _tokenIds[i], price, i + 1);
		}
		emit TrackMinted(s.totalTracks.current(), s.mxvLatestTokenId.current(), price, URIHash);
	}

	function purchaseTrackNFT(uint256 tokenId) public payable whenNotPaused {
		address _prevOwner = ownerOf(tokenId);
		LibMusixverse.purchaseToken(tokenId, s.trackNFTs, payable(s.PLATFORM_ADDRESS), s.PLATFORM_FEE_PERCENTAGE, s.mxvLatestTokenId);
		// Transfer ownership to buyer
		_safeTransferFrom(_prevOwner, msg.sender, tokenId, 1, "");
		s._owners[tokenId] = msg.sender;
		// Trigger an event
		emit TokenPurchased(tokenId, _prevOwner, msg.sender, msg.value);
	}

	function updatePrice(uint256 tokenId, uint256 newPrice) public {
		(uint256 _oldPrice, uint256 _newPrice) = LibMusixverse.updateTokenPrice(
			payable(s.PLATFORM_ADDRESS),
			tokenId,
			s.trackNFTs,
			newPrice,
			s.mxvLatestTokenId
		);
		// Trigger an event
		emit TokenPriceUpdated(tokenId, _oldPrice, _newPrice);
	}

	function toggleOnSale(uint256 tokenId) public {
		bool _onSale = LibMusixverse.toggleOnSaleAttribute(payable(s.PLATFORM_ADDRESS), tokenId, s.trackNFTs, s.mxvLatestTokenId);
		// Trigger an event
		emit TokenOnSaleUpdated(tokenId, _onSale);
	}

	// @notice Called with the token id to determine how much royalty is owed and to whom
	// @param tokenId - the NFT asset queried for royalty information
	// @return RoyaltyInfo[] - an array of type RoyaltyInfo having objects with the following fields: recipient, percentage
	// @info recipient - address of who should be sent the royalty payment
	// @info percentage - the royalty payment percentage
	function getRoyaltyInfo(uint256 tokenId) public view returns (RoyaltyInfo[] memory) {
		return s.royalties[tokenId];
	}

	// function _updateAccount(
	// 	uint256 _tokenId,
	// 	address _from,
	// 	address _to
	// ) internal {
	// 	uint256 length = s.royalties[_tokenId].length;
	// 	for (uint256 i = 0; i < length; i++) {
	// 		if (s.royalties[_tokenId][i].recipient == _from) {
	// 			s.royalties[_tokenId][i].recipient = payable(address(uint160(_to)));
	// 		}
	// 	}
	// }
}
