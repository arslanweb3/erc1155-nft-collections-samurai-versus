// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import "../src/Collection.sol";
import "../src/RoyaltyBalancer.sol";
import {console} from "forge-std/console.sol";

contract CollectionTest is Test {

    Collection public collection;

    RoyaltyBalancer public royaltyBalancer1;
    RoyaltyBalancer public royaltyBalancer2;

    address public minter1 = address(0x1111111);
    address public minter2 = address(0x2222222);
    address public minter3 = address(0x3333333);
    address public minter4 = address(0x4444444);
    address public minter5 = address(0x5555555);
    address public minter6 = address(0x6666666);

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
        vm.label(minter5, "minter 5");
        vm.label(minter6, "minter 6");
    }

    function testLinkings() external {
        assertEq(address(collection.royaltyBalancer1()), address(royaltyBalancer1));
        assertEq(address(collection.royaltyBalancer2()), address(royaltyBalancer2));

        console.log("1 royalty balancer address: ", address(royaltyBalancer1));
        console.log("2 royalty balancer address: ", address(royaltyBalancer2));
        console.log("Collection address: ", address(collection));
    }

    function testWhitelist() public {
        address[] memory accounts = new address[](4);
        accounts[0] = minter1;
        accounts[1] = minter2;
        accounts[2] = minter3;
        accounts[3] = minter4;

        // TODO test "addToWhitelistInLoop" function
        collection.addToWhitelistInLoop(accounts);

        // TODO test "checkIfWhitelisted" function
    
        /// @notice minter1, minter2, minter3 and minter4 are whitelisted
        assertEq(collection.checkIfWhitelisted(minter1), true);
        assertEq(collection.checkIfWhitelisted(minter2), true);
        assertEq(collection.checkIfWhitelisted(minter3), true);
        assertEq(collection.checkIfWhitelisted(minter4), true);

        /// @notice: minter5 and minter6 are not whitelisted
        assertEq(collection.checkIfWhitelisted(minter5), false);
        assertEq(collection.checkIfWhitelisted(minter6), false);
    }

    function testDeployCollectionParams() public {

        // TODO test that minter1, minter2, minter3 & minter4's "isApprovedForAll" to OpenSea = true
        assertEq(collection.checkApprovedForAll(minter1, address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)), true);
        assertEq(collection.checkApprovedForAll(minter2, address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)), true);
        assertEq(collection.checkApprovedForAll(minter3, address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)), true);
        assertEq(collection.checkApprovedForAll(minter4, address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)), true);

        // minter5 is NOT whitelisted but his "isApprovedForAll" to OpenSea = true
        // anyway he still can't transfer tokens cause' he didn't mint them
        vm.startPrank(minter5);
        assertEq(collection.checkApprovedForAll(minter5, address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)), true);
        vm.stopPrank();

        // TODO test that minter1's "isApprovedForAll" to minter2 = false
        vm.startPrank(minter1);

        console.log("Approved? -", collection.checkApprovedForAll(minter1, minter2));
        assertEq(collection.checkApprovedForAll(minter1, minter2), false);

        /// @notice here we set "isApprovedForAll" to minter2 = true
        collection.setApprovalForAll(minter2, true);

        // TODO test that minter1's "isApprovedForAll" to minter2 = true and works correctly
        console.log("Approved? -", collection.checkApprovedForAll(minter1, minter2));
        assertEq(collection.checkApprovedForAll(minter1, minter2), true);
        vm.stopPrank();
    }

    function testMintWaterSamurai() public {
        collection.addToWhitelist(minter1);
        collection.addToWhitelist(minter5);

        vm.deal(minter1, 10000 ether);

        vm.startPrank(minter1);

        // TODO test that we can mint 10 water samurai tokens 
        collection.mintWaterSamurai{value: 100 ether}(10);
        assertEq(collection.checkBalance(minter1, 0), 10);

        vm.stopPrank();


        /// @notice minter5 is not whitelisted and so can't mint
        vm.deal(minter5, 10000 ether);
        vm.startPrank(minter5);


        uint256[] memory amounts = new uint256[](2); 
        amounts[0] = 10;
        amounts[1] = 10;

        collection.mintBatch{value: 200 ether}(amounts);
        // collection.mintBatch{value: 200 ether}(amounts);


        assertEq(collection.checkBalance(minter5, 0), 10);
        assertEq(collection.checkBalance(minter5, 1), 10);

        vm.stopPrank();


        // for (uint i = 0; i < 50; i++) {
        //     vm.deal(minter1, 10000 ether);
        //     vm.startPrank(minter1);

        //     collection.mintWaterSamurai{value: 100 ether}(10);
        //     assertEq(collection.checkBalance(minter1, 0), 10);
        //     vm.stopPrank();
        // }
    }
}
