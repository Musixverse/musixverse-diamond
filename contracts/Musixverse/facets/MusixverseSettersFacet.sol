// contracts/Musixverse/facets/MusixverseSettersFacet.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { MusixverseEternalStorage } from "../common/MusixverseEternalStorage.sol";
import { Modifiers } from "../common/Modifiers.sol";

contract MusixverseSettersFacet is MusixverseEternalStorage, Modifiers {
	function updateName(string memory newName) public onlyOwner {
		s.name = newName;
	}

	function updateSymbol(string memory newSymbol) public onlyOwner {
		s.symbol = newSymbol;
	}

	function updateContractURI(string memory newURI) public onlyOwner {
		s.contractURI = newURI;
	}

	function updateBaseURI(string memory newURI) public onlyOwner {
		s.baseURI = newURI;
	}

	function updatePlatformFeePercentage(uint8 newPlatformFeePercentage) public onlyOwner {
		s.PLATFORM_FEE_PERCENTAGE = newPlatformFeePercentage;
	}

	function updateReferralCutPercentage(uint8 newReferralCutPercentage) public onlyOwner {
		s.REFERRAL_CUT = newReferralCutPercentage;
	}
}
