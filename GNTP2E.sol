// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./GNT.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IP2ERelease {
  function newReleaseSchedule(address player, uint256 totalReward) external;
}

contract GNTP2E is GNT {
  using SafeMath for uint256;

  // flag denoting that all p2e rewards have been exhausted
  bool public maxedOut = false;

  // max total supply for p2e distribution
  uint256 public p2emaxTotalSupply;

  // distributionName is a string representing the name of the distribution for this contract
  string public distributionName;

  // transactionFee is a percentage of the reward that is deducted as a transaction fee
  uint256 public transactionFee;

  // stagesPerc is an array of percentages that define the distribution of rewards among stages
  uint256[] public stagesPerc;

  // stagesAPY is an array of annual percentage yields (APYs) for each stage
  uint256[] public stagesAPY;

  // currentStage is an index representing the current stage of the reward distribution
  uint16 public currentStage;

  // the wallet that will receive the taxed tokens
  address private taxWallet;

  // TreasuryPool contract address
  address private treasuryPool;

  // contract that manages linear release of reward
  address private p2ereleasecontract = address(0);

  event RewardPlayer(
    uint256 totalMinted,
    uint256 fee,
    uint256 reward,
    address indexed player,
    uint256 indexed timestamp
  );

  /**
   * @dev Initializes the contract with the given parameters and sets the stagesPerc and stagesAPY arrays.
   * @param _treasuryPool address of TreasuryPool contract
   * @param _distributionName The name of the distribution for this contract.
   * @param _maxTotalSupply The maximum total supply of the token.
   * @param _distributionNames An array of distribution names for the token.
   * @param _distributionPercentages An array of distribution percentages for the token.
   * @param _transactionFee The percentage of the reward that is deducted as a transaction fee.
   * @param _taxWallet The wallet that will receive the taxed tokens
   * @param _stagesPerc An array of percentages that define the distribution of rewards among stages.
   * @param _stagesAPY An array of annual percentage yields (APYs) for each stage.
   */
  constructor(
    address _treasuryPool,
    string memory _distributionName,
    uint256 _maxTotalSupply,
    string[] memory _distributionNames,
    uint256[] memory _distributionPercentages,
    uint256 _transactionFee,
    address _taxWallet,
    uint256[] memory _stagesPerc,
    uint256[] memory _stagesAPY
  ) GNT(_maxTotalSupply, _distributionNames, _distributionPercentages) {
    treasuryPool = _treasuryPool;

    // Set the distribution name and transaction fee
    distributionName = _distributionName;
    transactionFee = _transactionFee;
    taxWallet = _taxWallet;

    // Set the stagesPerc and stagesAPY arrays
    stagesPerc = _stagesPerc;
    stagesAPY = _stagesAPY;

    // calculate total supply for p2e
    p2emaxTotalSupply = maxTotalSupply.mul(
      distributionPercentages[distributionName]
    );

    // Check that the length of the stagesPerc and stagesAPY arrays match
    require(
      stagesPerc.length == stagesAPY.length,
      "stage data mismatch lengths"
    );
  }

  modifier onlyTreasuryPool() {
    require(msg.sender == treasuryPool, "not treasuryPool");
    _;
  }

  function setReleaseContract(address contractAddr) public onlyOwner {
    p2ereleasecontract = contractAddr;
  }

  /**
   * @dev Mint tokens for P2E distribution and update the current stage.
   * @param to The address to which the minted tokens will be transferred.
   * @param amount The amount of tokens to be minted.
   * @return A boolean that indicates if the operation was successful.
   */
  function _mintP2E(address to, uint256 amount) internal returns (bool) {
    _mintD(distributionName, to, amount);
    uint256 distributedAmount = distributedSupply[distributionName];
    uint256 acc = 0;

    for (uint256 i = 0; i < stagesPerc.length; i++) {
      uint256 stageAmount = p2emaxTotalSupply.mul(stagesPerc[i]).div(ONE);
      acc = acc.add(stageAmount);
      if (distributedAmount <= acc) {
        currentStage = uint16(i);
      } else {
        break;
      }
    }
    return true;
  }

  function mintP2E(address to, uint256 amount) public onlyOwner returns (bool) {
    return _mintP2E(to, amount);
  }

  /**
   * @dev Set the APY for a specific stage.
   * @param stage The index of the stage.
   * @param apy The annual percentage yield (APY) for the stage.
   */
  function setAPY(uint256 stage, uint256 apy) public onlyOwner {
    require(stage >= 0 && stage < stagesPerc.length, "invalid stage");
    stagesAPY[stage] = apy;
  }

  /**
   * @dev Set the transaction fee for this contract.
   * @param newFee The new transaction fee.
   */
  function setTransactionFee(uint256 newFee) public onlyOwner {
    transactionFee = newFee;
  }

  /**
   * @dev calculate how much reward to mint given the amount played
   * @param played the amount played
   * @return (total to mint including taxes, flag if possible to mint reward)
   */
  function p2ecalculatereward(uint256 played)
    public
    view
    returns (uint256, bool)
  {
    uint256 apy = stagesAPY[currentStage];
    uint256 totalMint = played.mul(apy).div(ONE);
    return (
      totalMint,
      distributedSupply[distributionName].add(totalMint) <=
        p2emaxTotalSupply.div(ONE)
    );
  }

  /**
   * @dev mint reward for player and tax wallet
   * @param totalMint The amount of tokens to mint including tax
   * @param player The address of the player.
   */
  function p2ereward(uint256 totalMint, address player)
    public
    onlyTreasuryPool
    returns (bool)
  {
    uint256 fee = totalMint.mul(transactionFee).div(ONE);
    uint256 reward = totalMint.sub(fee);

    if (p2ereleasecontract != address(0)) {
      _mintP2E(taxWallet, fee);
      // send out fee to hot wallet (ed's client wallet)

      _mintP2E(p2ereleasecontract, reward);
      // send out reward to player

      IP2ERelease(p2ereleasecontract).newReleaseSchedule(player, reward);
      // inform 60 day release contract

      return true;
    }
    emit RewardPlayer(totalMint, fee, reward, player, block.timestamp);
    return false;
  }
}
