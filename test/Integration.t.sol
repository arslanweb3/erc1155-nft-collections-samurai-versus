// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {stdStorage, stdError, StdStorage, Test} from "forge-std/Test.sol";
import "../src/GenesisWaterSamurai.sol";
import "../src/RoyaltyBalancer.sol";
import "../src/IRoyaltyBalancer.sol";
import {console} from "forge-std/console.sol";

// @notice run forge test --match-test testIntegration or forge test -vv
// p.s. This 'testIntegration' function tests only 'GenesisWaterSamurai.sol' since 'GenesisFireSamurai.sol' smart-contract is almost the same as 'GenesisWaterSamurai.sol'

contract IntegrationTest is Test {
    error MintLimitReached();
    error TotalSupplyMinted();
    error ExceededFreeMintAmount();
    error FreeMintNotEnabled();
    error AlreadyClaimed();

    // @notice Water & Fire samurai NFT collection
    GenesisWaterSamurai public genesisWaterSamuraiCollection;

    // @notice Personal royalty balancer smart-contract for each NFT collection
    RoyaltyBalancer public royaltyBalancerGenesisWaterSamurai;

    // @notice 11 unwhitelisted addresses (minters)
    address public minter1 = address(0x1); // whatever address
    address public minter2 = address(0x2); 
    address public minter3 = address(0x3);
    address public minter4 = address(0x4);
    address public minter5 = address(0x5);
    address public minter6 = address(0x6);
    address public minter7 = address(0x7);
    address public minter8 = address(0x8);
    address public minter9 = address(0x9);
    address public minter10 = address(0x10);
    address public minter11 = address(0x11);

    address public newOwner = address(0x77777777777777777777); // whatever address

    // @notice OpenSea marketplace
    address payable public openSeaMarketplace = payable(address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101));

    function setUp() public {
      royaltyBalancerGenesisWaterSamurai = new RoyaltyBalancer();
      vm.label(address(royaltyBalancerGenesisWaterSamurai), "Royalty balancer for water samurais");

      genesisWaterSamuraiCollection = new GenesisWaterSamurai(IRoyaltyBalancer(royaltyBalancerGenesisWaterSamurai));
      vm.label(address(genesisWaterSamuraiCollection), "Genesis Water samurais NFT collection");

      royaltyBalancerGenesisWaterSamurai.setCollectionAddress(address(genesisWaterSamuraiCollection));

      // @notice We give OpenSea marketplace 100 BNB
      vm.label(address(openSeaMarketplace), "OpenSea marketplace");
      vm.deal(openSeaMarketplace, 100 ether); // 100 BNB 

      // @notice We give each minter 2 BNB to pay for mint, for gas fee and some extra BNB
      vm.deal(minter1, 2 ether); // 2 BNB
      vm.deal(minter2, 2 ether); // 2 BNB
      vm.deal(minter3, 2 ether); // 2 BNB
      vm.deal(minter4, 2 ether); // 2 BNB
      vm.deal(minter5, 2 ether); // 2 BNB
      vm.deal(minter6, 2 ether); // 2 BNB
      vm.deal(minter7, 2 ether); // 2 BNB
      vm.deal(minter8, 2 ether); // 2 BNB
      vm.deal(minter9, 2 ether); // 2 BNB
      vm.deal(minter10, 2 ether); // 2 BNB
      vm.deal(minter11, 2 ether); // 2 BNB

      address[] memory accounts = new address[](11);

      accounts[0] = minter1;
      accounts[1] = minter2;
      accounts[2] = minter3;
      accounts[3] = minter4;
      accounts[4] = minter5;
      accounts[5] = minter6;
      accounts[6] = minter7;
      accounts[7] = minter8;
      accounts[8] = minter9;
      accounts[9] = minter10;
      accounts[10] = minter11;

      // @notice Add to whitelist 11 minters
      genesisWaterSamuraiCollection.addToWhitelist(accounts);
    }

    function testIntegration() public { 

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("0) TESTING OWNERSHIP TRANSFERING");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("I deployed genesis water samurai collection contract and owner of that contract is:", genesisWaterSamuraiCollection.owner());
        console.log("I deployed roaylty balancer contract and owner of that contract is:", royaltyBalancerGenesisWaterSamurai.owner());

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("I am (developer) transfering ownership of these contracts to new owner");

        genesisWaterSamuraiCollection.transferOwnership(address(newOwner));
        royaltyBalancerGenesisWaterSamurai.transferOwnership(address(newOwner));

        assertEq(genesisWaterSamuraiCollection.owner(), address(newOwner));
        assertEq(royaltyBalancerGenesisWaterSamurai.owner(), address(newOwner));

        vm.stopPrank();

        console.log("Genesis Water Samurai collection's new owner address is:", genesisWaterSamuraiCollection.owner());
        console.log("Royalty balancer contract's new owner address is:", royaltyBalancerGenesisWaterSamurai.owner());

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("1) TESTING FREE MINT STAGE");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Say we want to give 11 samurai tokens to mint for free to 11 specific users who won them in contest");

        vm.startPrank(genesisWaterSamuraiCollection.owner());

        address[] memory accounts = new address[](11);
        accounts[0] = minter1;
        accounts[1] = minter2;
        accounts[2] = minter3;
        accounts[3] = minter4;
        accounts[4] = minter5;
        accounts[5] = minter6;
        accounts[6] = minter7;
        accounts[7] = minter8;
        accounts[8] = minter9;
        accounts[9] = minter10;
        accounts[10] = minter11;

        uint256[] memory amounts = new uint256[](11);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;
        amounts[4] = 1;
        amounts[5] = 1;
        amounts[6] = 1;
        amounts[7] = 1;
        amounts[8] = 1;
        amounts[9] = 1;
        amounts[10] = 1;

        genesisWaterSamuraiCollection.addToFreeMintList(accounts, amounts);

        vm.stopPrank();

        console.log("I added minters to 'addToFreeMintList' and gave each of them 1 token to mint for free");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Let's test that 'addToFreeMintList' function works correctly and minters can mint for free:");

        console.log("------------------");    

        (bool minter1bool, uint256 minter1amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter1));
        console.log("Is minter1 eligibled to mint for free? -", minter1bool, " Amount of tokens he can mint -", minter1amount);

        (bool minter2bool, uint256 minter2amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter2));
        console.log("Is minter2 eligibled to mint for free? -", minter2bool, " Amount of tokens he can mint -", minter2amount);

        (bool minter3bool, uint256 minter3amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter3));
        console.log("Is minter3 eligibled to mint for free? -", minter3bool, " Amount of tokens he can mint -", minter3amount);

        (bool minter4bool, uint256 minter4amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter4));
        console.log("Is minter4 eligibled to mint for free? -", minter4bool, " Amount of tokens he can mint -", minter4amount);

        (bool minter5bool, uint256 minter5amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter5));
        console.log("Is minter5 eligibled to mint for free? -", minter5bool, " Amount of tokens he can mint -", minter5amount);

        (bool minter6bool, uint256 minter6amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter6));
        console.log("Is minter6 eligibled to mint for free? -", minter6bool, " Amount of tokens he can mint -", minter6amount);

        (bool minter7bool, uint256 minter7amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter7));
        console.log("Is minter7 eligibled to mint for free? -", minter7bool, " Amount of tokens he can mint -", minter7amount);

        (bool minter8bool, uint256 minter8amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter8));
        console.log("Is minter8 eligibled to mint for free? -", minter8bool, " Amount of tokens he can mint -", minter8amount);

        (bool minter9bool, uint256 minter9amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter9));
        console.log("Is minter9 eligibled to mint for free? -", minter9bool, " Amount of tokens he can mint -", minter9amount);

        (bool minter10bool, uint256 minter10amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter10));
        console.log("Is minter10 eligibled to mint for free? -", minter10bool, " Amount of tokens he can mint -", minter10amount);

        (bool minter11bool, uint256 minter11amount) = genesisWaterSamuraiCollection.isFreeMintEligibled(address(minter11));
        console.log("Is minter11 eligibled to mint for free? -", minter11bool, " Amount of tokens he can mint -", minter11amount);

        console.log("--------------------------------------------------------------------------------------------------------"); 

        console.log("Minter1 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter1);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter1), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter1), 1), 1);
        vm.stopPrank();

        console.log("Minter1's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter1), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 10);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("Say minter2 is trying to overcome his free mint limit of 1 token, he is minting 2 tokens:");
        console.log("It's supposed to revert with custom error: ExceededFreeMintAmount()");

        vm.startPrank(minter2);
        vm.expectRevert(ExceededFreeMintAmount.selector);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter2), 2);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), 0);
        vm.stopPrank();

        console.log("Minter2's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter2), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 10);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("Say minter2 understood that it was bad decision so he is trying to mint his 1 token for free:");

        vm.startPrank(minter2);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter2), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), 1);
        vm.stopPrank();

        console.log("Minter2's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter2), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 9);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        // console.log("Wait.. Can minter2 mint another token he isn't eligibled? Let's test this scenario");
        // console.log("It's supposed to revert with custom error: AlreadyClaimed()");

        // vm.startPrank(minter2);
        // vm.expectRevert(AlreadyClaimed.selector);
        // genesisWaterSamuraiCollection.claimFreeTokens(address(minter2), 1);
        // assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), 1);
        // vm.stopPrank();

        // console.log("Minter2's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter2), 1));

        // assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 9);
        // console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        // console.log("------------------");    

        console.log("Minter3 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter3);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter3), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter3), 1), 1);
        vm.stopPrank();

        console.log("Minter3's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter3), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 8);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("Minter4 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter4);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter4), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter4), 1), 1);
        vm.stopPrank();

        console.log("Minter4's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter4), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 7);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("Minter5 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter5);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter5), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter5), 1), 1);
        vm.stopPrank();

        console.log("Minter5's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter5), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 6);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");       

        console.log("Minter7 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter7);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter7), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter7), 1), 1);
        vm.stopPrank();

        console.log("Minter7's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter7), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 5);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("Minter8 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter8);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter8), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter8), 1), 1);
        vm.stopPrank();

        console.log("Minter8's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter8), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 4);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("Minter9 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter9);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter9), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter9), 1), 1);
        vm.stopPrank();

        console.log("Minter9's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter9), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 3);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");    

        console.log("--------------------------------------------------------------------------------------------------------"); 

        console.log("Minter6 is trying to mint 10 tokens (now all actions are happening from him):");

        vm.startPrank(minter6);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.5 ether}(address(minter6), 10);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter6), 1), 10);
        vm.stopPrank();

        console.log("Minter6's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter6), 1));
        console.log("Minter6 payed 0.5 BNB to mint 10 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("------------------");    

        console.log("Minter6 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter6);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter6), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter6), 1), 11);
        vm.stopPrank();

        console.log("Minter6's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter6), 1), "(+1 token because he claimed it for free)");

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 2);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------"); 

        assertEq(genesisWaterSamuraiCollection.totalSupply(), 19);
        console.log("Show total supply:", genesisWaterSamuraiCollection.totalSupply());

        console.log("--------------------------------------------------------------------------------------------------------"); 

        // TODO when you will be testing, try this scenario
        // console.log("------------------");  

        // console.log("Can NOT eligibled owner or some NOT eligibled person claim free token? Let's test");
        // console.log("It's supposed to revert with reason: You can't mint for free!");

        // vm.startPrank(genesisWaterSamuraiCollection.owner());
        // genesisWaterSamuraiCollection.claimFreeTokens(genesisWaterSamuraiCollection.owner(), 1);
        // assertEq(genesisWaterSamuraiCollection.balanceOf(genesisWaterSamuraiCollection.owner(), 1), 0);
        // vm.stopPrank();

        // console.log("Owner's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(genesisWaterSamuraiCollection.owner(), 0));

        // assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 0);
        // console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("2) TESTING PAYED MINT STAGE");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("In setUp() function we have whitelisted 11 minters, let's check if they can mint:");

        console.log("--------------------------------------------------------------------------------------------------------");

        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter1)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter2)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter3)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter4)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter5)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter6)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter7)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter8)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter9)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter10)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter11)), true);

        console.log("Is minter1 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter1)));
        console.log("Is minter2 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter2)));
        console.log("Is minter3 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter3)));
        console.log("Is minter4 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter4)));
        console.log("Is minter5 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter5)));
        console.log("Is minter6 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter6)));
        console.log("Is minter7 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter7)));
        console.log("Is minter8 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter8)));
        console.log("Is minter9 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter9)));
        console.log("Is minter10 whitelisted?", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter10)));
        console.log("Is minter11 whitelisted?", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter11)));

        console.log("--------------------------------------------------------------------------------------------------------");

        vm.startPrank(genesisWaterSamuraiCollection.owner());
        address[] memory newAccounts = new address[](6);
        newAccounts[0] = minter6;
        newAccounts[1] = minter7;
        newAccounts[2] = minter8;
        newAccounts[3] = minter9;
        newAccounts[4] = minter10;
        newAccounts[5] = minter11;

        console.log("Now let's remove 6 minters from whitelist,");
        console.log("then we will add them again to check if our whitelisting functions work properly:");

        console.log("--------------------------------------------------------------------------------------------------------");

        genesisWaterSamuraiCollection.removeFromWhitelist(newAccounts);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter6)), false);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter7)), false);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter8)), false);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter9)), false);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter10)), false);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter11)), false);

        console.log("Is minter6 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter6)));
        console.log("Is minter7 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter7)));
        console.log("Is minter8 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter8)));
        console.log("Is minter9 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter9)));
        console.log("Is minter10 whitelisted?", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter10)));
        console.log("Is minter11 whitelisted?", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter11)));
      
        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Add minters to whitelist!");

        console.log("--------------------------------------------------------------------------------------------------------");

        genesisWaterSamuraiCollection.addToWhitelist(newAccounts);
        vm.stopPrank();    

        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter6)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter7)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter8)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter9)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter10)), true);
        assertEq(genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter11)), true);

        console.log("Is minter6 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter6)));
        console.log("Is minter7 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter7)));
        console.log("Is minter8 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter8)));
        console.log("Is minter9 whitelisted? ", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter9)));
        console.log("Is minter10 whitelisted?", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter10)));
        console.log("Is minter11 whitelisted?", genesisWaterSamuraiCollection.isMinterWhitelisted(address(minter11)));

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Now let's say it's mint time!");

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter1 is trying to mint 10 tokens (now all actions are happening from him):");

        vm.startPrank(minter1);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.5 ether}(address(minter1), 10);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter1), 1), 11);

        console.log("Minter1's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter1), 1), "(+1 token because he claimed it for free)");
        console.log("Minter1 payed 0.5 BNB to mint 10 tokens.");

        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals).");

        console.log("--------------------------------------------------------------------------------------------------------");       

        console.log("Now let's say minter1 is trying to overcome max mint limit of 10 tokens.");
        console.log("It's supposed to revert with custom error: MintLimitReached()");

        vm.expectRevert(MintLimitReached.selector);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.5 ether}(address(minter1), 10);
        vm.stopPrank();    

        console.log("Minter1's balance of water samurai tokens is still:", genesisWaterSamuraiCollection.balanceOf(address(minter1), 1));

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter2 is trying to mint 4 tokens (now all actions are happening from him):");

        vm.startPrank(minter2);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.2 ether}(address(minter2), 4);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), 5);
        vm.stopPrank();        

        console.log("Minter2's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), "(+1 token because he claimed it for free)");
        console.log("Minter2 payed 0.2 BNB to mint 4 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals).");

        console.log("--------------------------------------------------------------------------------------------------------"); 
        console.log("------------------");   

        console.log("Minter10 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter10);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter10), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter10), 1), 1);
        vm.stopPrank();

        console.log("Minter10's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter10), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 1);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");  

        console.log("Minter11 is trying to mint 1 token for free (now all actions are happening from him):");

        vm.startPrank(minter11);
        genesisWaterSamuraiCollection.claimFreeTokens(address(minter11), 1);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter11), 1), 1);
        vm.stopPrank();

        console.log("Minter11's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter11), 1));

        assertEq(genesisWaterSamuraiCollection.freeMintAmount(), 0);
        console.log("Show remaining reserved tokens for free mint (this amount decreases with each mint):", genesisWaterSamuraiCollection.freeMintAmount());

        console.log("------------------");  
        console.log("--------------------------------------------------------------------------------------------------------"); 

        console.log("Minter3 is trying to mint 3 tokens (now all actions are happening from him):");

        vm.startPrank(minter3);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.15 ether}(address(minter3), 3);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter3), 1), 4);
        vm.stopPrank();

        console.log("Minter3's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter3), 1), "(+1 token because he claimed it for free)");
        console.log("Minter3 payed 0.15 BNB to mint 3 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter4 is trying to mint 7 tokens (now all actions are happening from him):");

        vm.startPrank(minter4);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.35 ether}(address(minter4), 7);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter4), 1), 8);
        vm.stopPrank();     

        console.log("Minter4's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter4), 1), "(+1 token because he claimed it for free)");
        console.log("Minter4 payed 0.35 BNB to mint 7 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter5 is trying to mint 6 tokens (now all actions are happening from him):");

        vm.startPrank(minter5);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.3 ether}(address(minter5), 6);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter5), 1), 7);
        vm.stopPrank();

        console.log("Minter5's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter5), 1), "(+1 token because he claimed it for free)");
        console.log("Minter4 payed 0.3 BNB to mint 6 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter2 is trying to mint 6 remaining tokens (now all actions are happening from him):");

        vm.startPrank(minter2);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.3 ether}(address(minter2), 6);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), 11);
        vm.stopPrank();

        console.log("Minter2's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter2), 1), "(+1 token because he claimed it for free)");
        console.log("Minter2 payed 0.3 BNB to mint remaining 6 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 
      
        console.log("--------------------------------------------------------------------------------------------------------");       

        console.log("Minter7 is trying to mint 2 tokens (now all actions are happening from him):");

        vm.startPrank(minter7);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.1 ether}(address(minter7), 2);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter7), 1), 3);
        vm.stopPrank();

        console.log("Minter7's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter7), 1), "(+1 token because he claimed it for free)");
        console.log("Minter7 payed 0.1 BNB to mint 2 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter8 is trying to mint 3 tokens (now all actions are happening from him):");

        vm.startPrank(minter8);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.15 ether}(address(minter8), 3);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter8), 1), 4);
        vm.stopPrank();

        console.log("Minter8's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter8), 1), "(+1 token because he claimed it for free)");
        console.log("Minter8 payed 0.15 BNB to mint 3 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter9 is trying to mint 5 tokens (now all actions are happening from him):");

        vm.startPrank(minter9);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.25 ether}(address(minter9), 5);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter9), 1), 6);
        vm.stopPrank();

        console.log("Minter9's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter9), 1), "(+1 token because he claimed it for free)");
        console.log("Minter9 payed 0.25 BNB to mint 5 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter10 is trying to mint 9 tokens (now all actions are happening from him):");

        vm.startPrank(minter10);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.45 ether}(address(minter10), 9);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter10), 1), 10);
        vm.stopPrank();

        console.log("Minter10's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter10), 1), "(+1 token because he claimed it for free)");
        console.log("Minter10 payed 0.45 BNB to mint 9 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Minter11 is trying to mint 10 tokens (now all actions are happening from him):");

        vm.startPrank(minter11);
        genesisWaterSamuraiCollection.mintSamurai{value: 0.5 ether}(address(minter11), 10);
        assertEq(genesisWaterSamuraiCollection.balanceOf(address(minter11), 1), 11);
        vm.stopPrank();

        console.log("Minter11's balance of water samurai tokens:", genesisWaterSamuraiCollection.balanceOf(address(minter11), 1), "(+1 token because he claimed it for free)");
        console.log("Minter11 payed 0.5 BNB to mint 10 tokens.");
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance, "(in decimals)."); 

        console.log("--------------------------------------------------------------------------------------------------------");   

        console.log("Let's check the total amount of minted tokens.");
        assertEq(genesisWaterSamuraiCollection.totalSupply(), 86);
        console.log("The collection's total supply is:", genesisWaterSamuraiCollection.totalSupply()); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Let's check how many BNB collection's contract has received.");
        assertEq(address(genesisWaterSamuraiCollection).balance, 3.75 ether);
        console.log("The collection's contract balance is:", address(genesisWaterSamuraiCollection).balance); 

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("3) WITHDRAW FUNDS");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Now let's say I (owner) want to withdraw all received BNB from collection's contract.");

        vm.startPrank(genesisWaterSamuraiCollection.owner()); 
        genesisWaterSamuraiCollection.withdrawFunds();
        assertEq(address(genesisWaterSamuraiCollection).balance, 0);
        vm.stopPrank();

        console.log("Collection's contract balance:", address(genesisWaterSamuraiCollection).balance);
        console.log("Address owner() of this collection's contract balance:", address(genesisWaterSamuraiCollection.owner()).balance);

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("4) TESTING ROYALTY");

        console.log("--------------------------------------------------------------------------------------------------------");   

        console.log("Now let's say I'm the OpenSea marketplace.");
        console.log("A lot of nft traders and users bought Water Samurai tokens from me. So I need to pay the royalties to the creator.");

        vm.startPrank(openSeaMarketplace);

        console.log("------------------");    

        console.log("I need to get some address for sending royalties from collection's contract.");

        console.log("I will call royaltyInfo() function with token ID (1) and total sales' amount (30 BNB) params to get:");
        console.log("(1) 'royaltyAddress'");
        console.log("(2) 'royaltyFee' amount to send to the roaylty receiver address (7%)");

        console.log("------------------");    

        (address royaltyAddress, uint256 royaltyFee) = genesisWaterSamuraiCollection.royaltyInfo(1, 30 ether); // 30 BNB
        assertEq(royaltyAddress, address(royaltyBalancerGenesisWaterSamurai));
        assertEq(royaltyFee, 2.1 ether); // 7% = 2.1 BNB 
        (bool success,) = payable(address(royaltyBalancerGenesisWaterSamurai)).call{value: royaltyFee}("");
        assertTrue(success);
        vm.stopPrank();

        console.log("Royalty address:", royaltyAddress);
        console.log("Royalty fee:", royaltyFee, "(7% = 2.1 BNB)");

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Here are shares for each minter");

        (uint256 shares1, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter1));
        console.log("Minter1:", shares1);

        (uint256 shares2, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter2));
        console.log("Minter2:", shares2);

        (uint256 shares3, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter3));
        console.log("Minter3:", shares3);

        (uint256 shares4, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter4));
        console.log("Minter4:", shares4);

        (uint256 shares5, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter5));
        console.log("Minter5:", shares5);

        (uint256 shares6, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter6));
        console.log("Minter3:", shares6);

        (uint256 shares7, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter7));
        console.log("Minter7:", shares7);

        (uint256 shares8, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter8));
        console.log("Minter7:", shares8);

        (uint256 shares9, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter9));
        console.log("Minter9:", shares9);

        (uint256 shares10, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter10));
        console.log("Minter10:", shares10);

        (uint256 shares11, ) = royaltyBalancerGenesisWaterSamurai.userInfo(address(minter11));
        console.log("Minter11:", shares11);

        console.log("--------------------------------------------------------------------------------------------------------");    

        console.log("Here are royaly fee rewards for each minter");
        console.log("P.S. Formula: 'royaltyFee' * 'shares' / 'totalShares'");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Minter1 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter1)), "(~0.268 BNB)");
        console.log("Minter2 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter2)), "(~0.268 BNB)");
        console.log("Minter3 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter3)), "(~0.0976 BNB)");
        console.log("Minter4 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter4)), "(~0.195 BNB)");
        console.log("Minter5 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter5)), "(~0.170 BNB)");
        console.log("Minter6 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter6)), "(~0.268 BNB)");
        console.log("Minter7 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter7)), "(~0.0732 BNB)");
        console.log("Minter8 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter8)), "(~0.0976 BNB)");
        console.log("Minter9 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter9)), "(~0.146 BNB)");
        console.log("Minter10 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter10)), "(~0.244 BNB)");
        console.log("Minter11 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter11)), "(~0.268 BNB)");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("4) TESTING CLAIMING ROYALTY FEE MINTERS' REWARDS FROM ROYALTY BALANCER CONTRACT");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Minter1 is trying to claim his BNB as royalty reward (now all actions are happening from him):");

        vm.startPrank(minter1);
        royaltyBalancerGenesisWaterSamurai.claimReward();

        console.log("Minter1 claimed his royalty fee from royalty balancer");
        console.log("Minter1 balance:", address(minter1).balance, "(~0.268 BNB + his initial 1.5 BNB - transactions fees)");
        (uint256 sharesAfterClaim, uint256 debtAfterClaim) = royaltyBalancerGenesisWaterSamurai.userInfo(minter1);

        assertEq(sharesAfterClaim, 11);
        assertEq(debtAfterClaim, 0.268604651162790690 ether);
        vm.stopPrank();

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("Minter7 is trying to claim his BNB as royalty reward (now all actions are happening from him):");

        vm.startPrank(minter7);
        royaltyBalancerGenesisWaterSamurai.claimReward();

        console.log("Minter7 claimed his royalty fee from royalty balancer");
        console.log("Minter7 balance:", address(minter7).balance, "(~0.0732 BNB + his initial 1.9 BNB - transactions fees)");
        (uint256 sharesAfterClaim_, uint256 debtAfterClaim_) = royaltyBalancerGenesisWaterSamurai.userInfo(minter7);

        assertEq(sharesAfterClaim_, 3);
        assertEq(debtAfterClaim_, 0.073255813953488370 ether);
        vm.stopPrank();

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("As you can see below, other minters royalty fee are still the same and it doesn't change when someone claims,");
        console.log("so the royalty distribution works properly!");

        console.log("------------------");    

        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter1), 0 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter2), 0.268604651162790690 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter3), 0.097674418604651160 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter4), 0.195348837209302320 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter5), 0.170930232558139530 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter6), 0.268604651162790690 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter7), 0 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter8), 0.097674418604651160 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter9), 0.146511627906976740 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter10), 0.244186046511627900 ether);
        assertEq(royaltyBalancerGenesisWaterSamurai.pendingReward(minter11), 0.268604651162790690 ether);

        console.log("Minter1 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter1)), "(BNB)");
        console.log("Minter2 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter2)), "(~0.268 BNB)");
        console.log("Minter3 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter3)), "(~0.0976 BNB)");
        console.log("Minter4 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter4)), "(~0.195 BNB)");
        console.log("Minter5 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter5)), "(~0.170 BNB)");
        console.log("Minter6 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter6)), "(~0.268 BNB)");
        console.log("Minter7 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter7)), "(BNB)");
        console.log("Minter8 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter8)), "(~0.0976 BNB)");
        console.log("Minter9 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter9)), "(~0.146 BNB)");
        console.log("Minter10 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter10)), "(~0.244 BNB)");
        console.log("Minter11 royaly fee reward:", royaltyBalancerGenesisWaterSamurai.pendingReward(address(minter11)), "(~0.268 BNB)");

        console.log("--------------------------------------------------------------------------------------------------------");

        console.log("5) TESTING METADATA");

        console.log("--------------------------------------------------------------------------------------------------------");

        vm.startPrank(openSeaMarketplace);

        console.log("Metadata uri link from 'uri()' function -", genesisWaterSamuraiCollection.uri(1));
        console.log("Metadata uri link from 'contractURI()' function -", genesisWaterSamuraiCollection.contractURI(1));
        console.log("Collection's name -", genesisWaterSamuraiCollection.name());
        console.log("Collection's symbol -", genesisWaterSamuraiCollection.symbol());

        console.log("--------------------------------------------------------------------------------------------------------");
    }
}
