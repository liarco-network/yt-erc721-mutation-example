//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/interfaces/IERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMutatedToken.sol";
import "./IMutationToken.sol";

/**
 * This project was created for educational purposes only.
 * Use it at your own risk, under the terms of the MIT license which is packed
 * with the code in the LICENSE file.
 *
 * @author Marco Lipparini <developer@liarco.net>
 */
contract MutatedToken is IMutatedToken, ERC721A, Ownable, ReentrancyGuard {
  uint8 constant MUTATION_TYPES = 2;

  IERC721A immutable GENESIS_TOKEN_CONTRACT;
  IMutationToken immutable MUTATION_TOKEN_CONTRACT;

  string public uriPrefix = '';
  string public uriSuffix = '.json';

  bool public canMutate = false;

  mapping (uint256 => TokenData) public tokenData;
  mapping (uint256 => bool[MUTATION_TYPES]) public hasBeenMutated;

  constructor(address _genesisTokenAddress, address _mutationTokenAddress) ERC721A("Mutated Token", "MT") {
    GENESIS_TOKEN_CONTRACT = IERC721A(_genesisTokenAddress);
    MUTATION_TOKEN_CONTRACT = IMutationToken(_mutationTokenAddress);
  }

  function mutate(uint256 _genesisTokenId, uint256 _mutationType) public nonReentrant {
    if (!canMutate) {
      revert MutationNotEnabled();
    }

    if (_mutationType >= MUTATION_TYPES) {
      revert InvalidMutationType();
    }

    if (GENESIS_TOKEN_CONTRACT.ownerOf(_genesisTokenId) != msg.sender) {
      revert YouMustOwnTheGenesisToken();
    }

    if (MUTATION_TOKEN_CONTRACT.balanceOf(msg.sender, _mutationType) < 1) {
      revert NotEnoughMutationToken();
    }

    if (hasBeenMutated[_genesisTokenId][_mutationType]) {
      revert AlreadyMutated();
    }

    hasBeenMutated[_genesisTokenId][_mutationType] = true;
    tokenData[_nextTokenId()] = TokenData(_genesisTokenId, _mutationType);

    emit Mutation(_genesisTokenId, _mutationType, _nextTokenId(), msg.sender);

    MUTATION_TOKEN_CONTRACT.burn(msg.sender, _mutationType, 1);
    _safeMint(msg.sender, 1);
  }

  function getMutationStatus(uint256 _tokenId) public view returns(MutationStatus memory) {
    if (_tokenId < 1 || _tokenId > GENESIS_TOKEN_CONTRACT.totalSupply()) {
      revert UriQueryForNonexistentToken();
    }

    bool[] memory mutationStatus = new bool[](MUTATION_TYPES);

    for (uint256 i = 0; i < MUTATION_TYPES; i++) {
      mutationStatus[i] = hasBeenMutated[_tokenId][i];
    }

    return MutationStatus(_tokenId, mutationStatus);
  }

  function walletMutationStatus(
    address _owner,
    uint256 _startId,
    uint256 _endId,
    uint256 _startBalance
  ) public view returns(MutationStatus[] memory, bool) {
    uint256 ownerBalance = GENESIS_TOKEN_CONTRACT.balanceOf(_owner) - _startBalance;
    MutationStatus[] memory tokensData = new MutationStatus[](ownerBalance);
    uint256 currentOwnedTokenIndex = 0;

    for (uint256 i = _startId; currentOwnedTokenIndex < ownerBalance && i <= _endId; i++) {
      if (GENESIS_TOKEN_CONTRACT.ownerOf(i) == _owner) {
        tokensData[currentOwnedTokenIndex] = getMutationStatus(i);

        currentOwnedTokenIndex++;
      }
    }

    assembly {
      mstore(tokensData, currentOwnedTokenIndex)
    }

    return (tokensData, currentOwnedTokenIndex < ownerBalance);
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setCanMutate(bool _canMutate) public onlyOwner {
    canMutate = _canMutate;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) {
      revert UriQueryForNonexistentToken();
    }

    string memory currentBaseURI = uriPrefix;

    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI,  Strings.toString(_tokenId), uriSuffix))
      : '';
  }

  function _startTokenId() override internal view virtual returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IMutatedToken).interfaceId || super.supportsInterface(interfaceId);
  }
}
