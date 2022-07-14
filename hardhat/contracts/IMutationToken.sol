//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

/**
 * This project was created for educational purposes only.
 * Use it at your own risk, under the terms of the MIT license which is packed
 * with the code in the LICENSE file.
 *
 * @author Marco Lipparini <developer@liarco.net>
 */
interface IMutationToken is IERC1155 {
  error YouMustOwnAllOfTheGenesisTokens();
  error AlreadyClaimed();
  error InsufficientFunds();
  error OnlyTheMutatedContractCanBurnTokensDirectly();
  error ClaimNotEnabled();
  error ExchangeNotEnabled();
  error InvalidTokenType();

  event Claim(uint256 indexed tokenId, address indexed from);

  struct ClaimStatus {
    uint256 tokenId;
    bool hasClaimed;
  }

  function burn(address _owner, uint256 _id, uint256 _amount) external;
}
