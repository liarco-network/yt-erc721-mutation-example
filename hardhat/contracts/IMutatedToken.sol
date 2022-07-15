//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * This project was created for educational purposes only.
 * Use it at your own risk, under the terms of the MIT license which is packed
 * with the code in the LICENSE file.
 *
 * @author Marco Lipparini <developer@liarco.net>
 */
interface IMutatedToken {
  error MutationNotEnabled();
  error InvalidMutationType();
  error YouMustOwnTheGenesisToken();
  error NotEnoughMutationToken();
  error AlreadyMutated();
  error UriQueryForNonexistentToken();

  event Mutation(uint256 indexed genesisTokenId, uint256 indexed mutationType, uint256 indexed mutatedTokenId, address owner);

  struct TokenData {
    uint256 genesisTokenId;
    uint256 mutationType;
  }

  struct MutationStatus {
    uint256 tokenId;
    bool[] hasBeenMutated;
  }
}
