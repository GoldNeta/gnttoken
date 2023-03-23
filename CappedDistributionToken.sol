// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title CappedDistributionToken
 * @dev Extension of ERC20 that allows for distribution of a capped supply of tokens.
 * The distribution of the total supply is tracked, and minting tokens requires that
 * the admin declares which distribution it is being minted for. A distribution is
 * defined as a percentage of the total supply, where 100% is equivalent to 10**18.
 * The contract is also Ownable, allowing for administrative control over token
 * minting and other functions.
 * Owner will carry out token burning from time to time to permanently remove the 
 * burnt tokens from circulation, reducing the total supply of the token.
 */
contract CappedDistributionToken is ERC20, Ownable {
  using SafeMath for uint256;

  uint256 public maxTotalSupply;
  mapping(string => uint256) public distributionPercentages;
  mapping(string => uint256) public distributedSupply;
  uint256 internal constant ONE = 10**18;

  /**
   * @dev Constructor function that initializes the contract with a name, symbol,
   * total supply cap, and an array of distribution names and percentages.
   * @param _maxTotalSupply The maximum total supply of the token.
   * @param _name The name of the token.
   * @param _symbol The symbol of the token.
   * @param _distributionNames An array of distribution names.
   * @param _distributionPercentages An array of distribution percentages.
   * The two arrays must have the same length, and the percentages must add up to 100%.
   */
  constructor(
    uint256 _maxTotalSupply,
    string memory _name,
    string memory _symbol,
    string[] memory _distributionNames,
    uint256[] memory _distributionPercentages
  ) ERC20(_name, _symbol) {
    require(
      _distributionNames.length == _distributionPercentages.length,
      "Arrays must have the same length"
    );
    maxTotalSupply = _maxTotalSupply;
    uint256 totalPercentage = 0;
    for (uint256 i = 0; i < _distributionNames.length; i++) {
      string memory distribution = _distributionNames[i];
      uint256 percentage = _distributionPercentages[i];
      require(
        percentage <= ONE,
        "Percentage must be less than or equal to 100%"
      );
      distributionPercentages[distribution] = percentage;
      totalPercentage = totalPercentage.add(percentage);
    }
    require(
      totalPercentage == ONE,
      "Distribution percentages must add up to 100%"
    );
  }

  /**
   * @dev Function to mint tokens for a specific distribution. Tokens can only be minted
   * by the contract owner. Minting a token for a distribution requires that the distribution
   * percentage is greater than 0, the total supply cap is not exceeded, and the distribution
   * cap is not exceeded.
   * @param distribution The name of the distribution.
   * @param to The address to mint tokens to.
   * @param amount The amount of tokens to mint.
   * @return A boolean indicating whether the operation was successful.
   */
  function _mintD(
    string memory distribution,
    address to,
    uint256 amount
  ) internal returns (bool) {
    require(distributionPercentages[distribution] > 0, "Invalid distribution");
    require(
      totalSupply().add(amount) <= maxTotalSupply,
      "Max total supply exceeded"
    );
    require(
      distributedSupply[distribution].add(amount) <=
        maxTotalSupply.mul(distributionPercentages[distribution]).div(ONE),
      "Distribution cap exceeded"
    );

    distributedSupply[distribution] = distributedSupply[distribution].add(
      amount
    );
    _mint(to, amount);

    return true;
  }

  function mintD(
    string memory distribution,
    address to,
    uint256 amount
  ) public onlyOwner returns (bool) {
    return _mintD(distribution, to, amount);
  }
}
