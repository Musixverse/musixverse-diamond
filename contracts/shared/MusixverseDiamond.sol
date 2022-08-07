// contracts/shared/MusixverseDiamond.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { IERC1155 } from "./interfaces/IERC1155.sol";

contract MusixverseDiamond {
	constructor(
		address _contractOwner,
		address _diamondCutFacet,
		address _diamondLoupeFacet
	) payable {
		LibDiamond.setContractOwner(_contractOwner);

		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		ds.supportedInterfaces[type(IERC1155).interfaceId] = true;

		// Add the diamondCut external function from the diamondCutFacet
		IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
		bytes4[] memory functionSelectors = new bytes4[](1);
		functionSelectors[0] = IDiamondCut.diamondCut.selector;
		cut[0] = IDiamondCut.FacetCut({
			facetAddress: _diamondCutFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: functionSelectors
		});
		// Add the IERC165.supportsInterface function
		bytes4[] memory supportsInterfaceFunctionSelectors = new bytes4[](1);
		supportsInterfaceFunctionSelectors[0] = IERC165.supportsInterface.selector;
		cut[1] = IDiamondCut.FacetCut({
			facetAddress: _diamondLoupeFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: supportsInterfaceFunctionSelectors
		});
		LibDiamond.diamondCut(cut, address(0), "");
	}

	// Find facet for function that is called and execute the
	// function if a facet is found and return any value.
	fallback() external payable {
		LibDiamond.DiamondStorage storage ds;
		bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
		// get diamond storage
		assembly {
			ds.slot := position
		}
		// get facet from function selector
		address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
		require(facet != address(0), "Diamond: Function does not exist");
		// Execute external function from facet using delegatecall and return any value.
		assembly {
			// copy function selector and any arguments
			calldatacopy(0, 0, calldatasize())
			// execute function call using the facet
			let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
			// get any return value
			returndatacopy(0, 0, returndatasize())
			// return any return value or error back to the caller
			switch result
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}

	/***********************************|
    |           Receive Funds           |
    |__________________________________*/

	event Received(address, uint256);

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function withdraw() public {
		LibDiamond.enforceIsContractOwner();
		payable(msg.sender).transfer(address(this).balance);
	}
}
