// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";

/**
 * This project was created for educational purposes only.
 * Use it at your own risk, under the terms of the MIT license which is packed
 * with the code in the LICENSE file.
 *
 * @author Marco Lipparini <developer@liarco.net>
 */
contract GenesisToken is ERC721A {
  constructor() ERC721A("GENESIS TOKEN", "GT") {
  }

  function mint(uint256 amount) public {
    _safeMint(msg.sender, amount);
  }

  function _startTokenId() override internal view virtual returns (uint256) {
    return 1;
  }
}
