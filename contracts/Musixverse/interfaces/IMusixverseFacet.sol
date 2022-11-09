// contracts/Musixverse/interfaces/IMusixverseFacet.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.4;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { RoyaltyInfo } from "../libraries/LibMusixverseAppStorage.sol";

interface IMusixverseFacet {
	/***********************************|
    |         MusixverseFacet           |
    |__________________________________*/
	function mintTrackNFT(
		uint16 amount,
		uint256 price,
		string calldata URIHash,
		address[] calldata collaborators,
		uint16[] calldata percentageContributions,
		uint16 resaleRoyaltyPercentage,
		bool onSale,
		uint256 unlockTimestamp
	) external returns (uint256);

	function purchaseTrackNFT(uint256 tokenId) external payable;

	function updatePrice(uint256 tokenId, uint256 newPrice) external;

	function toggleOnSale(uint256 tokenId) external;

	function updateCommentOnToken(uint256 _tokenId, string memory _comment) external;

	/***********************************|
    |              Helpers              |
    |__________________________________*/

	function uri(uint256 mxvTokenId) external view returns (string memory);

	function ownerOf(uint256 tokenId) external view returns (address);
}
