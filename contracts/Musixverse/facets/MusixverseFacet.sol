// contracts/Musixverse/facets/MusixverseFacet.sol
// SPDX-License-Identifier: BSL 1.1
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
import { MusixverseEternalStorage } from "../common/MusixverseEternalStorage.sol";
import { TrackNftCreationData, Track, Token, RoyaltyInfo } from "../libraries/LibMusixverseAppStorage.sol";
import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { LibMusixverse } from "../libraries/LibMusixverse.sol";
import { Counters } from "../libraries/LibCounters.sol";
import { Modifiers } from "../common/Modifiers.sol";
import "hardhat/console.sol";

contract MusixverseFacet is MusixverseEternalStorage, ERC1155, Pausable, Modifiers, ReentrancyGuard {
	using SafeMath for uint256;
	using Counters for Counters.Counter;

	constructor(string memory baseURI_, string memory contractURI_) ERC1155(string(abi.encodePacked(baseURI_, "{id}"))) {
		__Musixverse_init_unchained(baseURI_, contractURI_);
	}

	function __Musixverse_init_unchained(string memory baseURI_, string memory contractURI_) public {
		s.name = "Musixverse";
		s.symbol = "MXV";
		s.PLATFORM_FEE_PERCENTAGE = 1;
		s.PLATFORM_ADDRESS = payable(address(this));
		s.REFERRAL_CUT = 10;
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

	// Overriding the uri function
	function uri(uint256 mxvTokenId) public view virtual override returns (string memory) {
		require(mxvTokenId > 0 && mxvTokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return string(abi.encodePacked(s.baseURI, s.trackNFTs[s.tokens[mxvTokenId].trackId].metadataHash));
	}

	function unlockableContentUri(uint256 mxvTokenId) public view virtual returns (string memory) {
		require(mxvTokenId > 0 && mxvTokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		// Require that nft owner is calling the function
		require(ownerOf(mxvTokenId) == msg.sender, "Must be token owner to call this function");
		return string(abi.encodePacked(s.baseURI, s.trackNFTs[s.tokens[mxvTokenId].trackId].unlockableContentHash));
	}

	function ownerOf(uint256 tokenId) public view returns (address) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.owners[tokenId];
	}

	// function mintTrackNFT(TrackNftCreationData calldata data) external virtual whenNotPaused nonReentrant {
	// 	LibMusixverse.checkForMinting(data);
	// 	uint256[] memory _tokenIds = new uint256[](data.amount);
	// 	uint256[] memory _tokenAmounts = new uint256[](data.amount);
	// 	for (uint256 i = 0; i < data.amount; i++) {
	// 		s.mxvLatestTokenId.increment(1);
	// 		_tokenIds[i] = s.mxvLatestTokenId.current();
	// 		_tokenAmounts[i] = 1;
	// 		_setTokenHash(s.mxvLatestTokenId.current(), data.URIHash);
	// 		_setUnlockableContentHash(s.mxvLatestTokenId.current(), data.unlockableContentURIHash);
	// 		LibMusixverse.setRoyalties(s.mxvLatestTokenId.current(), data.collaborators, data.percentageContributions, s.royalties);
	// 		s.owners[s.mxvLatestTokenId.current()] = msg.sender;
	// 		s.trackNFTs[s.mxvLatestTokenId.current()] = Track(
	// 			data.price,
	// 			msg.sender,
	// 			data.resaleRoyaltyPercentage,
	// 			data.onSale,
	// 			false,
	// 			data.unlockTimestamp
	// 		);
	// 	}
	// 	_mintBatch(msg.sender, _tokenIds, _tokenAmounts, "");
	// 	s.totalTracks.increment(1);
	// 	for (uint256 i = 0; i < data.amount; i++) {
	// 		emit TokenCreated(msg.sender, s.totalTracks.current(), _tokenIds[i], data.price, i + 1);
	// 	}
	// 	emit TrackMinted(msg.sender, s.totalTracks.current(), s.mxvLatestTokenId.current(), data.price, data.URIHash);
	// }

	// function mintTrackNFT(TrackNftCreationData calldata data) external virtual whenNotPaused nonReentrant {
	// 	LibMusixverse.checkForMinting(data);

	// 	uint256[] memory _tokenIds = new uint256[](data.amount);
	// 	uint256[] memory _tokenAmounts = new uint256[](data.amount);

	// 	s.totalTracks.increment(1);
	// 	LibMusixverse.setRoyalties(s.totalTracks.current(), data.collaborators, data.percentageContributions, s.royalties);
	// 	s.trackNFTs[s.totalTracks.current()] = Track(
	// 		data.URIHash,
	// 		data.unlockableContentURIHash,
	// 		msg.sender,
	// 		data.resaleRoyaltyPercentage,
	// 		data.unlockTimestamp
	// 	);

	// 	for (uint256 i = 0; i < data.amount; i++) {
	// 		s.mxvLatestTokenId.increment(1);
	// 		_tokenIds[i] = s.mxvLatestTokenId.current();
	// 		_tokenAmounts[i] = 1;

	// 		s.owners[s.mxvLatestTokenId.current()] = msg.sender;
	// 		s.tokens[s.mxvLatestTokenId.current()] = Token(s.totalTracks.current(), data.price, data.onSale, false);
	// 	}

	// 	_mintBatch(msg.sender, _tokenIds, _tokenAmounts, "");

	// 	for (uint256 i = 0; i < data.amount; i++) {
	// 		emit TokenCreated(msg.sender, s.totalTracks.current(), _tokenIds[i], data.price, i + 1);
	// 	}
	// 	emit TrackMinted(msg.sender, s.totalTracks.current(), s.mxvLatestTokenId.current(), data.price, data.URIHash);
	// }

	// Use lazy minting in a different way. Storing of track data is done when the track is created (Also store number of copies and keep a check when collector purchases). Minting is done each time whenever a buyer purchases an NFT. Emit event for each token created. This way, we can keep track of the number of tokens minted for each track.
	function mintTrackNFT(TrackNftCreationData calldata data) external virtual whenNotPaused nonReentrant {
		LibMusixverse.checkForMinting(data);

		s.totalTracks.increment(1);
		LibMusixverse.setRoyalties(s.totalTracks.current(), data.collaborators, data.percentageContributions, s.royalties);
		s.trackNFTs[s.totalTracks.current()] = Track(
			data.URIHash,
			data.unlockableContentURIHash,
			msg.sender,
			data.resaleRoyaltyPercentage,
			data.unlockTimestamp,
			data.price
		);

		for (uint256 i = 0; i < data.amount; i++) {
			s.mxvLatestTokenId.increment(1);
			emit TokenCreated(msg.sender, s.totalTracks.current(), s.mxvLatestTokenId.current(), data.price, i + 1);
		}
		emit TrackMinted(msg.sender, s.totalTracks.current(), s.mxvLatestTokenId.current(), data.price, data.URIHash);
	}

	function purchaseTrackNFT(
		uint256 tokenId,
		uint256 trackId,
		address payable referrer
	) public payable whenNotPaused nonReentrant {
		address _prevOwner = ownerOf(tokenId);

		if (_prevOwner == address(0) && s.tokens[tokenId].trackId == 0) {
			_mint(s.trackNFTs[trackId].artistAddress, tokenId, 1, "");
			s.owners[tokenId] = s.trackNFTs[trackId].artistAddress;
			s.tokens[tokenId] = Token(trackId, s.trackNFTs[trackId].listingPrice, true, false);
		}

		address _reffererAddress = address(0);
		if (referrer != address(0)) {
			_reffererAddress = referrer;
		}
		_prevOwner = ownerOf(tokenId);
		LibMusixverse.purchaseToken(tokenId, payable(_reffererAddress), s.trackNFTs, s.tokens, s.mxvLatestTokenId);
		// Transfer ownership to buyer
		_safeTransferFrom(_prevOwner, msg.sender, tokenId, 1, "");
		s.owners[tokenId] = msg.sender;
		// Trigger an event
		emit TokenPurchased(tokenId, _reffererAddress, _prevOwner, msg.sender, msg.value);
		toggleOnSale(tokenId);
	}

	function updatePrice(uint256 tokenId, uint256 newPrice) public nonReentrant {
		(uint256 _oldPrice, uint256 _newPrice) = LibMusixverse.updateTokenPrice(
			payable(s.PLATFORM_ADDRESS),
			tokenId,
			s.tokens,
			newPrice,
			s.mxvLatestTokenId
		);
		// Trigger an event
		emit TokenPriceUpdated(msg.sender, tokenId, _oldPrice, _newPrice);
	}

	function toggleOnSale(uint256 tokenId) public {
		bool _onSale = LibMusixverse.toggleOnSaleAttribute(payable(s.PLATFORM_ADDRESS), tokenId, s.trackNFTs, s.tokens, s.mxvLatestTokenId);
		// Trigger an event
		emit TokenOnSaleUpdated(msg.sender, tokenId, _onSale);
	}

	function updateCommentOnToken(uint256 _tokenId, string memory _comment) public virtual nonReentrant {
		string memory _previousComment = LibMusixverse.updateComment(
			payable(s.PLATFORM_ADDRESS),
			_tokenId,
			_comment,
			s.commentWall,
			s.mxvLatestTokenId
		);
		// Trigger an event
		emit TokenCommentUpdated(msg.sender, _tokenId, _previousComment, _comment);
	}

	// @notice Called with the token id to determine how much royalty is owed and to whom
	// @param tokenId - the NFT asset queried for royalty information
	// @return RoyaltyInfo[] - an array of type RoyaltyInfo having objects with the following fields: recipient, percentage
	// @info recipient - address of who should be sent the royalty payment
	// @info percentage - the royalty payment percentage
	function getRoyaltyInfo(uint256 tokenId) public view returns (RoyaltyInfo[] memory) {
		return s.royalties[s.tokens[tokenId].trackId];
	}
}
