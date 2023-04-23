// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RoyaltyBalancer.sol";

contract RoyaltyBalancerTest is Test {
    RoyaltyBalancer public royaltyBalancer;
    address public collection = address(0x1111111);
    address public minter1 = address(0x2222222);
    address public minter2 = address(0x3333333);
    address public minter3 = address(0x4444444);

    function setUp() public {
        vm.deal(collection, 100 ether);
        royaltyBalancer = new RoyaltyBalancer();
        royaltyBalancer.setCollectionAddress(collection);
    }

    /// @dev https://docs.google.com/spreadsheets/d/1iQJPHIopqlURifxPxo9MGo67t9Kjibf7Kvul3KnAvpQ/edit?usp=sharing
    function testBasicFlow() public {
        vm.startPrank(collection);
        assertEq(royaltyBalancer.totalShares(), 0);

        royaltyBalancer.addMinterShare(minter1, 1);
        assertEq(royaltyBalancer.totalShares(), 1);
        (uint256 shares, uint256 debt) = royaltyBalancer.userInfo(minter1);
        assertEq(shares, 1);
        assertEq(debt, 0);
        assertEq(royaltyBalancer.pendingReward(minter1), 0);
        assertEq(royaltyBalancer.accRewardPerShare(), 0);

        (bool success,) = payable(address(royaltyBalancer)).call{value: 1 ether}("");
        assertEq(success, true);
        assertEq(royaltyBalancer.accRewardPerShare(), 1 ether);
        assertEq(royaltyBalancer.pendingReward(minter1), 1 ether);
        assertEq(royaltyBalancer.pendingReward(minter2), 0);
        assertEq(royaltyBalancer.pendingReward(minter3), 0);

        royaltyBalancer.addMinterShare(minter2, 1);
        assertEq(royaltyBalancer.totalShares(), 2);
        (shares, debt) = royaltyBalancer.userInfo(minter2);
        assertEq(shares, 1);
        assertEq(debt, 1 ether);
        assertEq(royaltyBalancer.accRewardPerShare(), 1 ether); // still
        assertEq(royaltyBalancer.pendingReward(minter1), 1 ether);
        assertEq(royaltyBalancer.pendingReward(minter2), 0);
        assertEq(royaltyBalancer.pendingReward(minter3), 0);

        (success,) = payable(address(royaltyBalancer)).call{value: 1 ether}("");
        assertEq(success, true);
        assertEq(royaltyBalancer.accRewardPerShare(), 1.5 ether);
        assertEq(royaltyBalancer.pendingReward(minter1), 1.5 ether);
        assertEq(royaltyBalancer.pendingReward(minter2), 0.5 ether);
        assertEq(royaltyBalancer.pendingReward(minter3), 0);

        changePrank(minter1);
        royaltyBalancer.claimReward();
        assertEq(royaltyBalancer.totalShares(), 2);
        (shares, debt) = royaltyBalancer.userInfo(minter1);
        assertEq(shares, 1);
        assertEq(debt, 1.5 ether);
        assertEq(royaltyBalancer.pendingReward(minter1), 0);
        assertEq(royaltyBalancer.accRewardPerShare(), 1.5 ether);
    }
}
