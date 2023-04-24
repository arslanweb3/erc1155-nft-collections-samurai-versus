// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import "../src/Collection.sol";
import "../src/RoyaltyBalancer.sol";
import {console} from "forge-std/console.sol";

contract IntegrationTest is Test {
    Collection public collection;

    RoyaltyBalancer public royaltyBalancer1;
    RoyaltyBalancer public royaltyBalancer2;

    address public minter1 = address(0x1111111);
    address public minter2 = address(0x2222222);
    address public minter3 = address(0x3333333);
    address public minter4 = address(0x4444444);

    address payable public marketplace = payable(address(0x5555555));

    function setUp() public {
      royaltyBalancer1 = new RoyaltyBalancer();
      royaltyBalancer2 = new RoyaltyBalancer();
      collection = new Collection(royaltyBalancer1, royaltyBalancer2);
      royaltyBalancer1.setCollectionAddress(address(collection));
      royaltyBalancer2.setCollectionAddress(address(collection));

      vm.label(address(royaltyBalancer1), "royalty balancer 1");
      vm.label(address(royaltyBalancer2), "royalty balancer 2");
      vm.label(address(collection), "collection");
      vm.label(minter1, "minter 1");
      vm.label(minter2, "minter 2");
      vm.label(minter3, "minter 3");
      vm.label(minter4, "minter 4");
      vm.label(marketplace, "marketplace");
      vm.deal(marketplace, 100 ether);
      vm.deal(minter1, 10000 ether);
      vm.deal(minter2, 10000 ether);

      address[] memory accounts = new address[](4);
      accounts[0] = minter1;
      accounts[1] = minter2;
      accounts[2] = minter3;
      accounts[3] = minter4;

      collection.addToWhitelistInLoop(accounts);

      changePrank(minter1);
      uint256[] memory amounts = new uint256[](2); 
      amounts[0] = 5;
      amounts[1] = 10;
      collection.mintBatch{value: 150 ether}(amounts);

      changePrank(minter2);
      amounts[0] = 10;
      amounts[1] = 5;
      collection.mintBatch{value: 150 ether}(amounts);
    }

    function testRoyaltyBalance() external {
      // ok, I'm a marketplace
      // Somebody bought a WaterSamurai token from me
      // I need to pay the royalties to the creator
      changePrank(marketplace);
      // I need to get royalty address from collection
      (address royaltyAddress, uint256 value) = collection.royaltyInfo(0, 30 ether);
      assertEq(royaltyAddress, address(royaltyBalancer1));
      assertEq(value, 2.1 ether);
      (bool result,) = payable(address(royaltyBalancer1)).call{value: value}("");
      assertTrue(result);
      // here are shares for minter1 and minter2:
      // minter1: 5
      // minter2: 10
      // so minter1 should get 2.1 * 5 / 15 = 0.7 ether
      // and minter2 should get 2.1 * 10 / 15 = 1.4 ether
      assertEq(royaltyBalancer1.pendingReward(minter1), 0.7 ether);
      assertEq(royaltyBalancer1.pendingReward(minter2), 1.4 ether);

      // okay next someone buys a FireSamurai token from me
      // I need to pay the royalties to the creator
      (royaltyAddress, value) = collection.royaltyInfo(1, 30 ether);
      assertEq(royaltyAddress, address(royaltyBalancer2));
      assertEq(value, 2.1 ether);
      (result,) = payable(address(royaltyBalancer2)).call{value: value}("");
      assertTrue(result);
      // here are shares for minter1 and minter2:
      // minter1: 10
      // minter2: 5
      // so minter1 should get 2.1 * 10 / 15 = 1.4 ether
      // and minter2 should get 2.1 * 5 / 15 = 0.7 ether
      assertEq(royaltyBalancer2.pendingReward(minter1), 1.4 ether);
      assertEq(royaltyBalancer2.pendingReward(minter2), 0.7 ether);
    }

    function testDumbMarketplace() external {
      // ok, I'm a marketplace
      // but I'm stupid and don't know how to get royalty address for a token
      // so I just send all the money to the collection
      // or I get royaltyInfo but for nonexistent tokenId
      changePrank(marketplace);
      (address royaltyAddress, uint256 value) = collection.royaltyInfo(123, 30 ether);
      assertEq(royaltyAddress, address(collection));
      assertEq(value, 2.1 ether);
      // I send 2.1 ether to the collection
      (bool result,) = payable(address(collection)).call{value: value}("");
      assertTrue(result);
      // now collection splits money to royaltyBalancers
      // asserted rewards are halves as from previous test
      assertEq(royaltyBalancer1.pendingReward(minter1), 0.35 ether);
      assertEq(royaltyBalancer1.pendingReward(minter2), 0.7 ether);
      assertEq(royaltyBalancer2.pendingReward(minter1), 0.7 ether);
      assertEq(royaltyBalancer2.pendingReward(minter2), 0.35 ether);
    }

    function testWithdraw() external {
      assertEq(address(collection).balance, 300 ether); // nfts minted in setUp

      vm.expectRevert("Ownable: caller is not the owner");
      collection.withdraw();

      // owner withdraws money from collection
      changePrank(collection.owner());
      collection.withdraw();
      // and now collection has 0 balance
      assertEq(address(collection).balance, 0);
    }

    receive() external payable {
      // needed to receive money from collection as this test contract is an owner
    }
}