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
import { TrackNftCreationData, TrackNftPurchaseValues, Track, Token, RoyaltyInfo } from "../libraries/LibMusixverseAppStorage.sol";
import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { LibMusixverse } from "../libraries/LibMusixverse.sol";
import { Counters } from "../libraries/LibCounters.sol";
import { Modifiers } from "../common/Modifiers.sol";
import { MusixverseSettersFacet } from "./MusixverseSettersFacet.sol";

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
		s.MINTER_ROLE = keccak256("MINTER_ROLE");
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

	function ownerOf(uint256 tokenId) public view returns (address) {
		require(tokenId > 0 && tokenId <= s.mxvLatestTokenId.current(), "Token DNE");
		return s.owners[tokenId];
	}

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
			data.price,
			s.mxvLatestTokenId.current() + 1,
			s.mxvLatestTokenId.current() + data.amount
		);

		for (uint256 i = 0; i < data.amount; i++) {
			s.mxvLatestTokenId.increment(1);
			emit TokenCreated(msg.sender, s.totalTracks.current(), s.mxvLatestTokenId.current(), data.price, i + 1);
		}
		// Trigger an event
		emit TrackMinted(msg.sender, s.totalTracks.current(), s.mxvLatestTokenId.current(), data.price, data.URIHash, data.URIHash);
	}

	function purchaseTrackNFT(
		uint256 tokenId,
		uint256 trackId,
		address payable referrer
	) public payable whenNotPaused nonReentrant {
		require(trackId > 0 && trackId <= s.totalTracks.current(), "Track DNE");
		address _prevOwner = ownerOf(tokenId);

		Track memory _trackNFT = s.trackNFTs[trackId];
		require(tokenId >= _trackNFT.minTokenId && tokenId <= _trackNFT.maxTokenId, "tokenId mismatch with trackId");

		if (_prevOwner == address(0) && s.tokens[tokenId].trackId == 0) {
			_mint(_trackNFT.artistAddress, tokenId, 1, "");
			s.owners[tokenId] = _trackNFT.artistAddress;
			s.tokens[tokenId] = Token(trackId, _trackNFT.listingPrice, true, false);
		}

		address _reffererAddress = address(0);
		if (referrer != address(0)) {
			_reffererAddress = referrer;
		}
		_prevOwner = ownerOf(tokenId);

		// Distribute funds
		TrackNftPurchaseValues memory _purchaseValues = LibMusixverse.purchaseToken(
			tokenId,
			payable(_reffererAddress),
			s.trackNFTs,
			s.tokens,
			s.mxvLatestTokenId
		);
		// Transfer ownership to buyer
		_safeTransferFrom(_prevOwner, msg.sender, tokenId, 1, "");
		s.owners[tokenId] = msg.sender;

		// Trigger an event
		emit TokenPurchased(
			tokenId,
			_reffererAddress,
			_purchaseValues.referralFee,
			_purchaseValues.platformFee,
			_purchaseValues.royaltyAmount,
			_prevOwner,
			_purchaseValues.value,
			msg.sender,
			msg.value
		);
		toggleOnSale(tokenId);
	}

	function updatePrice(uint256 tokenId, uint256 newPrice) public whenNotPaused nonReentrant {
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

	function toggleOnSale(uint256 tokenId) public virtual whenNotPaused {
		bool _onSale = LibMusixverse.toggleOnSaleAttribute(payable(s.PLATFORM_ADDRESS), tokenId, s.trackNFTs, s.tokens, s.mxvLatestTokenId);
		// Trigger an event
		emit TokenOnSaleUpdated(msg.sender, tokenId, _onSale);
	}

	function updateCommentOnToken(uint256 _tokenId, string memory _comment) public virtual whenNotPaused nonReentrant {
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
}
