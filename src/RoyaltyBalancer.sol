// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract RoyaltyBalancer is IRoyaltyBalancer, Ownable {

  /* ****** */
  /* ERRORS */
  /* ****** */

  error OnlyCollection();

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
  uint256 public accRewardPerShare;

  modifier onlyCollection() {
    if (msg.sender != collection) {
      revert OnlyCollection();
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
    userInfo[minter].debt = accRewardPerShare * userInfo[minter].shares;
  }

  // @notice Allows to see how many rewards minter has (in wei)
  function pendingReward(address minter) public view returns (uint256) {
    UserInfo storage user = userInfo[minter];
    return accRewardPerShare * user.shares - user.debt;
  }

  // @notice Allows any user that has 'shares' to claim his rewards 
  function claimReward() external /* can be executed by any user */ {
    UserInfo storage user = userInfo[msg.sender];
    if (user.shares == 0) {
      return;
    }
    uint256 pending = pendingReward(msg.sender);
    user.debt = accRewardPerShare * user.shares;
    (bool success, ) = msg.sender.call{value: pending}("");
    require(success, "Couldn't send minter claiming funds");
  }

  // @notice When someone (supposed to be marketplace) sends funds to this contract (which is set as royalty receiver), 
  // reward per 1 share for each minter increases
  receive() external payable {
    accRewardPerShare = accRewardPerShare + msg.value / totalShares;
  }
}
