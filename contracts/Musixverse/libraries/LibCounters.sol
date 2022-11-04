// contracts/Musixverse/libraries/Counters.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.4;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

/**
 * @title Counters
 * @author Pushpit (@pushpit07)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC1155 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
	struct Counter {
		// This variable should never be directly accessed by users of the library: interactions must be restricted to
		// the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
		// this feature: see https://github.com/ethereum/solidity/issues/4637
		uint256 _value; // default: 0
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter, uint256 amount) internal {
		require(amount > 0, "Counter: increment amount should be greater than 0");
		unchecked {
			counter._value += amount;
		}
	}

	function decrement(Counter storage counter, uint256 amount) internal {
		require(amount > 0, "Counter: decrement amount should be greater than 0");
		uint256 value = counter._value;
		require(value > 0, "Counter: decrement overflow");
		require(value - amount >= 0, "Counter: difference should be greater than or equal to 0");
		unchecked {
			counter._value = value - amount;
		}
	}

	function reset(Counter storage counter) internal {
		counter._value = 0;
	}
}
