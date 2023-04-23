// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Events} from "./Events.sol";
import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

// TODO shares denominator for more precision


contract RoyaltyBalancer is Events, IRoyaltyBalancer, Ownable {
  address public collection;

  constructor() {}

  function setCollectionAddress(address _collection) public onlyOwner {
    collection = _collection;
  }

  modifier onlyCollection() {
    if (msg.sender != collection) {
      revert OnlyCollection();
    }
    _;
  }

  struct UserInfo {
    uint256 shares;
    uint256 debt; // in wei
  }

  uint256 public totalShares;
  uint256 public accRewardPerShare;

  mapping(address => UserInfo) public userInfo;

  function addMinterShare(address minter, uint256 amount) external onlyCollection {
    totalShares = totalShares + amount;
    userInfo[minter].shares += amount;
    userInfo[minter].debt = accRewardPerShare * userInfo[minter].shares;
  }

  function pendingReward(address minter) public view returns (uint256) {
    UserInfo storage user = userInfo[minter];
    return accRewardPerShare * user.shares - user.debt;
  }

  function claimReward() external /* can be executed by any user */ {
    UserInfo storage user = userInfo[msg.sender];
    if (user.shares == 0) {
      return;
    }
    uint256 pending = pendingReward(msg.sender);
    user.debt = accRewardPerShare * user.shares;
    payable(msg.sender).transfer(pending);
  }

  receive() external payable {
    accRewardPerShare = accRewardPerShare + msg.value / totalShares;
  }
}
