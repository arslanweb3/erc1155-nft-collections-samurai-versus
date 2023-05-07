// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRoyaltyBalancer {
  function addMinterShare(address minter, uint256 amount) external;
  function pendingReward(address minter) external view returns (uint256);
  function claimReward() external;
  function userInfo(address) external view returns (uint256 shares, uint256 debt);
}
