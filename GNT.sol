// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CappedDistributionToken.sol";

contract GNT is CappedDistributionToken {
  uint256 public p2eTransactionFee;

  constructor(
    uint256 _maxTotalSupply,
    string[] memory _distributionNames,
    uint256[] memory _distributionPercentages
  )
    CappedDistributionToken(
      _maxTotalSupply,
      "Goldneta Token",
      "GNT",
      _distributionNames,
      _distributionPercentages
    )
  {}
}
