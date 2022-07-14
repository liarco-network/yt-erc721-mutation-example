//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMutationToken.sol";

/**
 * This project was created for educational purposes only.
 * Use it at your own risk, under the terms of the MIT license which is packed
 * with the code in the LICENSE file.
 *
 * @author Marco Lipparini <developer@liarco.net>
 */
contract MutationToken is IMutationToken, ERC1155, Ownable, ReentrancyGuard {
  uint256 constant BASIC_TYPE_ID = 0;
  uint256 constant PREMIUM_TYPE_ID = 1;
  uint8 constant PREMIUM_TYPE_PRICE = 3;
  string constant URI_SUFFIX = '.json';

  IERC721 immutable GENESIS_TOKEN_CONTRACT;

  address public mutatedContractAddress = address(0);

  bool public canClaim = false;
  bool public canExchange = false;

  mapping (uint256 => bool) public hasClaimed;

  constructor(address _genesisTokenAddress, string memory _uriPrefix) ERC1155(_uriPrefix) {
    GENESIS_TOKEN_CONTRACT = IERC721(_genesisTokenAddress);
  }

  function claim(uint256[] memory _tokenIds) public nonReentrant {
    if (!canClaim) {
      revert ClaimNotEnabled();
    }

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];

      if (GENESIS_TOKEN_CONTRACT.ownerOf(tokenId) != msg.sender) {
        revert YouMustOwnAllOfTheGenesisTokens();
      }

      if (hasClaimed[tokenId] == true) {
        revert AlreadyClaimed();
      }

      hasClaimed[tokenId] = true;

      emit Claim(tokenId, msg.sender);
    }

    _mint(msg.sender, BASIC_TYPE_ID, _tokenIds.length, "");
  }

  function buyPremiumToken(uint8 _amount) public nonReentrant {
    if (!canExchange) {
      revert ExchangeNotEnabled();
    }

    uint256 price = _amount * PREMIUM_TYPE_PRICE;

    if (balanceOf(msg.sender, BASIC_TYPE_ID) < price) {
      revert InsufficientFunds();
    }

    _burn(msg.sender, BASIC_TYPE_ID, price);
    _mint(msg.sender, PREMIUM_TYPE_ID, _amount, "");
  }

  function burn(address _owner, uint256 _id, uint256 _amount) external {
    if (address(0) == mutatedContractAddress || msg.sender != mutatedContractAddress) {
      revert OnlyTheMutatedContractCanBurnTokensDirectly();
    }

    _burn(_owner, _id, _amount);
  }

  function walletClaimStatus(
    address _owner,
    uint256 _startId,
    uint256 _endId,
    uint256 _startBalance
  ) public view returns(ClaimStatus[] memory, bool) {
    uint256 ownerBalance = GENESIS_TOKEN_CONTRACT.balanceOf(_owner) - _startBalance;
    ClaimStatus[] memory tokensData = new ClaimStatus[](ownerBalance);
    uint256 currentOwnedTokenIndex = 0;

    for (uint256 i = _startId; currentOwnedTokenIndex < ownerBalance && i <= _endId; i++) {
      if (GENESIS_TOKEN_CONTRACT.ownerOf(i) == _owner) {
        tokensData[currentOwnedTokenIndex] = ClaimStatus(i, hasClaimed[i]);

        currentOwnedTokenIndex++;
      }
    }

    assembly {
      mstore(tokensData, currentOwnedTokenIndex)
    }

    return (tokensData, currentOwnedTokenIndex < ownerBalance);
  }

  function uri(uint256 _id) public view virtual override returns (string memory) {
    if (_id != BASIC_TYPE_ID && _id != PREMIUM_TYPE_ID) {
      revert InvalidTokenType();
    }

    string memory currentUriPrefix = super.uri(_id);

    return bytes(currentUriPrefix).length > 0
      ? string(abi.encodePacked(currentUriPrefix, Strings.toString(_id), URI_SUFFIX))
      : currentUriPrefix;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    _setURI(_uriPrefix);
  }

  function setCanClaim(bool _canClaim) public onlyOwner {
    canClaim = _canClaim;
  }

  function setCanExchange(bool _canExchange) public onlyOwner {
    canExchange = _canExchange;
  }

  function setMutatedContractAddress(address _mutatedContractAddress) public onlyOwner {
    mutatedContractAddress = _mutatedContractAddress;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, IERC165) returns (bool) {
    return interfaceId == type(IMutationToken).interfaceId || super.supportsInterface(interfaceId);
  }
}
