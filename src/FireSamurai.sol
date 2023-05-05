// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";

// @title ....
// @author ....
// @notice .....

contract FireSamurai is ERC1155, ERC2981, Ownable, ReentrancyGuard, Pausable {

    /* ****** */
    /* ERRORS */
    /* ****** */
    
    error MintLimitReached();
    error TotalSupplyMinted();
    error ExceededFreeMintAmount();
    error LengthNotIdentical();
    error FreeMintNotEnabled();
    error FreeMintEnabled();
    error AlreadyClaimed();

    /* ****** */
    /* EVENTS */
    /* ****** */

    event MintedTokens(address minter, uint256 tokenId, uint256 amount);
    event ClaimedTokens(address claimer, uint256 tokenId, uint256 amount);
    event AddedMinterShares(address minter, uint256 tokenId, uint256 amount);
    
    /* ******* */
    /* STORAGE */
    /* ******* */

    string public name;
    string public symbol;

    // @notice To keep track of how many tokens have been minted and how many are left to be minted.
    uint256 public totalSupply = 0;
    string public baseURI;
    string public _contractURI = 'https://bafybeidugntaxvpfdk3vi2de4tnh3y6jx3wogka4jfwty7ai35hj57oepm.ipfs.dweb.link/water_samurai.json';

    // @notice This is the maximum amount that whitelisted minter can mint
    uint256 public constant MAX_AMOUNT = 10;

    // @notice All minters can mint multiple tokens with 1 token ID (this is how the ERC115 standard works)
    uint256 public constant FIRE_SAMURAI_TOKEN_ID = 1;

    // @notice This is the maximum amount of tokens (samurais) that can be minted by all users
    uint256 public constant MAX_MINT_AMOUNT = 500;

    // TODO change the mint price when will be deploying on Mainnet
    // @notice Mint price 0.05 ether = 15$ per 1 token (in BNB currency) 
    uint256 public constant MINT_PRICE = 0.05 ether; 

    // @notice "royaltyFee" in basis point (=7%)
    uint96 public constant ROYALTY_FEE = 700; 

    // @notice This '10' (!) amount is being reserved for free minters and each time someone claims tokens this variable's count decreases
    uint256 public freeMintAmount = 10;

    // TODO set the "royaltyBalancer" address during deploying on Mainnet
    // @notice "royaltyBalancer" smart-contract for receiving, managing and distributing royalty fee rewards
    // from secondary sales to initial minters 
    IRoyaltyBalancer public immutable royaltyBalancer;

    // @notice This mapping is used to set whitelisted addresses
    mapping(address => bool) public whitelisted;

    // @notice These mappings are used to 1) set addresses that can mint few tokens for free, 
    // 2) set their amount of tokens they are eligibled and when someone claims tokens
    // 3) to keep of track of that action and in 'mintSamurai' function check 
    // that if user has already claimed then don't consider this free claimed amount and let him mint his max limit of 10 tokens for BNB
    mapping(address => bool) public freeMintEligibled;
    mapping(address => uint256) public amountEligibled;
    mapping(address => uint256) public claimedFreeMintTokens;

    // @notice Used instead of require() to check that address is whitelisted to mint tokens
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "You are not whitelisted!");
        _;
    }

    // @notice Used instead of require() to check that address is free mint eligibled to claim tokens for free
    modifier onlyFreeMintEligibled() {
        require(freeMintEligibled[msg.sender], "You can't mint for free!");
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor(IRoyaltyBalancer _royaltyBalancer) ERC1155("https://bafybeidugntaxvpfdk3vi2de4tnh3y6jx3wogka4jfwty7ai35hj57oepm.ipfs.dweb.link/water_samurai.json") {
        name = 'Fire Samurai Token';
        symbol = 'FST';
        royaltyBalancer = IRoyaltyBalancer(_royaltyBalancer);
        baseURI = 'https://bafybeidugntaxvpfdk3vi2de4tnh3y6jx3wogka4jfwty7ai35hj57oepm.ipfs.dweb.link/water_samurai.json';

        setDefaultRoyalty(address(royaltyBalancer));
        setTokenRoyalty(address(royaltyBalancer));
    }

    // ********* MINT FUNCTIONS ********* //
    // @notice This function allows particular users to mint for free/claim new tokens tokens of 'FIRE_SAMURAI_TOKEN_ID'.
    // Only 'freeMintEligibled' addresses can mint tokens. Initial minters are then being added to royalty balancer contract state 
    // with their shares (1 minted token = 1 share), so that they would be able to claim their royalty fee rewards.
    function claimFreeTokens(address to, uint256 amount) public payable nonReentrant whenNotPaused onlyFreeMintEligibled {

        if (amount > amountEligibled[to]) {
            revert ExceededFreeMintAmount();
        }

        _mint(to, FIRE_SAMURAI_TOKEN_ID, amount, "");
        emit MintedTokens(to, FIRE_SAMURAI_TOKEN_ID, amount);

        // @notice We use 'unchecked' block to tell the compiler not to check for over/underflows since it will never do.
        // This thing will help to save up some gas for minters.
        unchecked {
            totalSupply += amount;
            claimedFreeMintTokens[to] += amount;
            freeMintAmount -= amount;
        }

        if (claimedFreeMintTokens[to] != amountEligibled[to]) {
            revert AlreadyClaimed();
        }
        emit ClaimedTokens(to, FIRE_SAMURAI_TOKEN_ID, amount);

        IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
        emit AddedMinterShares(to, FIRE_SAMURAI_TOKEN_ID, amount);
    }

    // @notice This function mints new tokens of 'FIRE_SAMURAI_TOKEN_ID'. Minters pay 15$ in BNB to mint 1 token.
    // Only whitelisted addresses can mint tokens. Initial minters are then being added to royalty balancer contract state 
    // with their shares (1 minted token = 1 share), so that they would be able to claim their royalty fee rewards.
    function mintSamurai(address to, uint256 amount) public payable nonReentrant whenNotPaused onlyWhitelisted {

        require(msg.value >= (amount * MINT_PRICE), "Not enough BNB sent. Check mint price!");

        // If minter overpaid, the remainder amount will be sent to his address
        if (msg.value > (amount * MINT_PRICE)) {
            uint256 remainderAmount = msg.value - (amount * MINT_PRICE);
            (bool success, ) = to.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder BNB to minter");
        }

        if (balanceOf(to, FIRE_SAMURAI_TOKEN_ID) + amount - claimedFreeMintTokens[to] > MAX_AMOUNT) {
            revert MintLimitReached();
        }

        // @notice We use 'unchecked' block to tell the compiler not to check for over/underflows since it will never do.
        // This thing will help to save up some gas for minters
        unchecked {
            totalSupply += amount;
        }

        if (totalSupply > MAX_MINT_AMOUNT - freeMintAmount) { 
            revert TotalSupplyMinted();
        }

        _mint(to, FIRE_SAMURAI_TOKEN_ID, amount, "");
        emit MintedTokens(to, FIRE_SAMURAI_TOKEN_ID, amount);

        IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
        emit AddedMinterShares(to, FIRE_SAMURAI_TOKEN_ID, amount);
    }

    // ********* ALLOWLIST MANAGING FUNCTIONS ********* //
    // @notice This function adds addresses in loop to free mint list mapping
    function addToFreeMintList(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {

        if (accounts.length != amounts.length) {
            revert LengthNotIdentical();
        }

        for (uint i; i < accounts.length; i++) {
            _addToFreeMintList(accounts[i], amounts[i]);
        }
    }

    // @notice This function adds addresses in loop to whitelist mapping
    function addToWhitelist(address[] calldata accounts) public onlyOwner {
    
        for (uint256 i; i < accounts.length; i++) {
            _addToWhitelist(accounts[i]);
        }
    }

    // @notice This function removes addresses in loop from whitelist mapping
    function removeFromWhitelist(address[] calldata accounts) public onlyOwner {
    
        for (uint256 i; i < accounts.length; i++) {
            _removeFromWhitelist(accounts[i]);
        }
    }

    // ********* INTERNAL ALLOWLIST MANAGING FUNCTIONS ********* //
    function _addToFreeMintList(address account, uint256 amount) internal {
        freeMintEligibled[account] = true;
        amountEligibled[account] = amount;
    }

    function _addToWhitelist(address account) internal {
        whitelisted[account] = true;
    }

    function _removeFromWhitelist(address account) internal {
        whitelisted[account] = false;
    }

    // ********* HELPER FUNCTIONS ********* //
    // @notice To check if minter's address is eligibled to mint/claim free tokens (front-end helpers)
    function isFreeMintEligibled(address minter) external view returns (bool, uint256) {
        return (freeMintEligibled[minter], amountEligibled[minter]);
    }

    // @notice To check if minter's address whitelisted (front-end helpers)
    function isMinterWhitelisted(address minter) external view returns (bool) {
        return whitelisted[minter];
    }

    // @notice To check how many tokens left to mint (front-end helpers)
    function checkRemainingTokens(address minter) external view returns (uint256) {
        uint256 remainingTokens = MAX_AMOUNT - balanceOf(minter, FIRE_SAMURAI_TOKEN_ID);
        return remainingTokens;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // @dev OpenSea whitelisting. This feature will allow users to list tokens on the marketplace without paying gas for an additional approval
        // If OpenSea's ERC1155 Proxy Address is detected, auto-return true
        if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(
            tokenId == FIRE_SAMURAI_TOKEN_ID,
            'ERC1155Metadata: URI query for nonexistent token'
        );
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI; // see: https://docs.opensea.io/docs/contract-level-metadata
    }

    // ********* ROYALTY MANAGING FUNCTIONS ********* //
    // @notice Allows owner() to set default address for royalty receiving for this contract's collection
    function setDefaultRoyalty(address receiver) public onlyOwner {
        _setDefaultRoyalty(receiver, ROYALTY_FEE);
    }

    // @notice Allows owner() to delete default address
    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    // @notice Allows owner() to set address for royalty receiving for 'FIRE_SAMURAI_TOKEN_ID'
    function setTokenRoyalty(address receiver) public onlyOwner {
        _setTokenRoyalty(FIRE_SAMURAI_TOKEN_ID, receiver, ROYALTY_FEE);
    }

    // @notice Allows owner() to reset address for royalty receiving for 'FIRE_SAMURAI_TOKEN_ID'
    function resetTokenRoyalty() public onlyOwner {
        _resetTokenRoyalty(FIRE_SAMURAI_TOKEN_ID);
    }

    // ********* MINT-PAUSE MANAGING FUNCTIONS ********* //
    // @notice Allows owner() to pause 'claimFreeTokens' and 'mintSamurai' functions
    function pause() public onlyOwner {
        _pause();
    }

    // @notice Allows owner() to unpause 'claimFreeTokens' and 'mintSamurai' functions
    function unpause() public onlyOwner {
        _unpause();
    }

    // ********* FUNDS MANAGING FUNCTIONS ********* //
    // @notice Allows owner() to withdraw funds from this contract
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Couldn't send funds to owner");
    }

    receive() external payable nonReentrant {}
}