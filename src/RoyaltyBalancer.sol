// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract RoyaltyBalancer is IRoyaltyBalancer, Ownable, ReentrancyGuard { 

  /* ****** */
  /* ERRORS */
  /* ****** */

  error OnlyCollection(string message);
  error NoShares();
  error EmptyContractBalance();

  /* ****** */
  /* EVENTS */
  /* ****** */

  event ClaimedReward(address claimer, uint256 claimedRewardAmount);
  event ReceivedRoyaltyFunds(address sender, uint256 receivedAmount);
  event AddedMinterShares(address minter, uint256 shares);

  /* ******* */
  /* STORAGE */
  /* ******* */

  address public collection;

  // @notie UserInfo struct to keep track of his shares and debt
  struct UserInfo {
    uint256 shares;
    uint256 debt; // in wei
  }

  uint256 public totalShares;
  uint256 public accumulatedRewardPerShare;

  modifier onlyCollection() {
    if (msg.sender != collection) {
      revert OnlyCollection("Only collection of Genesis Water/Fire Samurai can add minter shares to this contract");
    }
    _;
  }

  // @notice Used instead of require() to check that address calling 'addMinterShare' function is 'collection'
  mapping(address => UserInfo) public userInfo;

  /* *********** */
  /* CONSTRUCTOR */
  /* *********** */

  constructor() {}

  /* *********** */
  /*  FUNCTIONS  */
  /* *********** */

  // @notice Allows owner() to set collection's contract address
  function setCollectionAddress(address _collection) public onlyOwner {
    collection = _collection;
  }

  // @notice Adds minter shares to the state
  function addMinterShare(address minter, uint256 amount) external onlyCollection {
    totalShares = totalShares + amount;
    userInfo[minter].shares += amount;
    userInfo[minter].debt = accumulatedRewardPerShare * userInfo[minter].shares;
    emit AddedMinterShares(minter, amount);
  }

  // @notice Allows to see how many rewards minter has (in wei)
  function pendingReward(address minter) public view returns (uint256) {
    UserInfo storage user = userInfo[minter];
    return accumulatedRewardPerShare * user.shares - user.debt;
  }

  // @notice Allows any user that has 'shares' to claim his rewards 
  function claimReward() external nonReentrant /* can be executed by any user */ {
    UserInfo storage user = userInfo[msg.sender];
    if (user.shares == 0) {
      revert NoShares();
    }

    uint256 pending = pendingReward(msg.sender);
    if (pending == 0) {
      revert EmptyContractBalance();
    }

    user.debt = accumulatedRewardPerShare * user.shares;

    (bool success, ) = msg.sender.call{value: pending}("");
    require(success, "Couldn't send minter claiming funds");

    emit ClaimedReward(msg.sender, pending);
  }

  // @notice When someone (supposed to be marketplace) sends funds to this contract (which is set as royalty receiver), 
  // accumulated reward per 1 share for each minter increases
  receive() external payable {
    accumulatedRewardPerShare = accumulatedRewardPerShare + msg.value / totalShares;
    emit ReceivedRoyaltyFunds(msg.sender, msg.value);
  }
}
