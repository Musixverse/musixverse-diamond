// contracts/AppStorageFacet.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { AppStorage } from "../libraries/LibAppStorage.sol";

contract AppStorageFacet {
	AppStorage internal s;
}
