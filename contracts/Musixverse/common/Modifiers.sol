// contracts/Musixverse/common/Modifiers.sol
// SPDX-License-Identifier: UNLICENSED
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

	event TokenCreated(address creator, uint256 trackId, uint256 tokenId, uint256 price, uint256 localTokenId);

	event TrackMinted(address creator, uint256 trackId, uint256 maxTokenId, uint256 price, string URIHash);

	event TokenPurchased(uint256 tokenId, address referrer, address previousOwner, address newOwner, uint256 price);

	event TokenPriceUpdated(address caller, uint256 tokenId, uint256 oldPrice, uint256 newPrice);

	event TokenOnSaleUpdated(address caller, uint256 tokenId, bool onSale);
}
