// contracts/Musixverse/common/Modifiers.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";

contract Modifiers {
	modifier onlyOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}

	/***********************************|
    |              Events               |
    |__________________________________*/

	event TokenCreated(address indexed creator, uint256 indexed trackId, uint256 indexed tokenId, uint256 price, uint256 localTokenId);

	event TrackMinted(address indexed creator, uint256 indexed trackId, uint256 maxTokenId, uint256 price, string indexed URIHash);

	event TokenPurchased(uint256 indexed tokenId, address indexed referrer, address previousOwner, address indexed newOwner, uint256 price);

	event TokenPriceUpdated(address indexed caller, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);

	event TokenOnSaleUpdated(address indexed caller, uint256 indexed tokenId, bool onSale);

	event TokenCommentUpdated(address indexed caller, uint256 indexed tokenId, string previousComment, string newComment);

	event ArtistVerified(address indexed caller, address indexed artistAddress, string indexed username);
}
