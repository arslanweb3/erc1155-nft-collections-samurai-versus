// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./IRoyaltyBalancer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// @title Water samurais ERC1155 NFT collection.
// @author @arsln_galimov (Telegram)
// @notice .....

contract WaterSamurai is ERC1155, ERC2981, Ownable, ReentrancyGuard, Pausable {

    /* ****** */
    /* ERRORS */
    /* ****** */
    
    error MintLimitReached();
    error TotalSupplyMinted();

    /* ****** */
    /* EVENTS */
    /* ****** */
    
    // later be described.....
    
    // @notice OpenZeppelin's Address and Strings libraries for ...
    using Address for address;
    using Strings for string;

    /* ******* */
    /* STORAGE */
    /* ******* */

    string public name;
    string public symbol;

    // @notice To keep track of how many tokens have been minted and how many are left to be minted.
    uint256 public totalSupply = 0;

    string private baseURI = '';
    string private _contractURI = '';

    // @notice This is the maximum amount that whitelisted minter can mint
    uint256 public constant MAX_AMOUNT = 10;

    // @notice All minters can mint multiple tokens with 1 token ID (this is how the ERC115 standard works)
    uint256 public constant WATER_SAMURAI_TOKEN_ID = 1;

    // @notice This is the maximum amount of tokens (samurais) that can be minted by all users
    uint256 public constant MAX_MINT_AMOUNT = 500;

    // TODO change the mint price when will be deploying on Mainnet

    // @notice Mint price 0.05 ether = 15$ per 1 token (in BNB currency) 
    uint256 public constant MINT_PRICE = 0.05 ether; 

    // @notice "royaltyFee" in basis point (=7%)
    uint96 private constant ROYALTY_FEE = 700; 

    // TODO set the "royaltyBalancer" address

    // @notice "royaltyBalancer" smart-contract for receiving, managing and distributing royalties 
    // from secondary sales to initial minters 
    IRoyaltyBalancer public immutable royaltyBalancer;

    // @notice This mapping is used to set whitelisted addresses
    mapping(address => bool) public whitelisted;

    // @notice To check that address calling mint function is whitelisted
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "You are not whitelisted!");
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor(address _royaltyBalancer) ERC1155("https://example.com/api/item/{id}.json") {
        name = '';
        symbol = '';
        royaltyBalancer = IRoyaltyBalancer(_royaltyBalancer); // либо в конструкторе или через функцию или константа
        baseURI = 'ipfs://QmaxBCL3UGoYnqg8xhjREfxiDLCUDbmTkwj6AcbUZavXmp/{id}.json';

        setDefaultRoyalty(address(royaltyBalancer));
        setTokenRoyalty(address(royaltyBalancer));
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    // @notice This 'mintSamurai' function mints tokens (water samurai). Each token costs 15$ in BNB. 
    // Only whitelisted addresses can mint tokens and those minters who initially minted, can claim royalty from secondary sales.
    function mintSamurai(address to, uint256 amount) public payable nonReentrant whenNotPaused onlyWhitelisted {
        require(msg.value >= (amount * MINT_PRICE), "Not enough BNB sent. Check mint price!");

        // If minter overpaid, the remainder amount will be sent to his address
        if (msg.value > (amount * MINT_PRICE)) {
            uint256 remainderAmount = msg.value - (amount * MINT_PRICE);
            (bool success, ) = to.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder BNB to minter");
        }

        if (balanceOf(to, WATER_SAMURAI_TOKEN_ID) + amount > MAX_AMOUNT) {
            revert MintLimitReached();
        }

        _mint(to, WATER_SAMURAI_TOKEN_ID, amount, "");

        // @notice We use 'unchecked' block to tell the compiler not to check for over/underflows since it will never do.
        // This thing will help to save up some gas for minters
        unchecked {
            totalSupply += amount;
        }

        if (totalSupply > MAX_MINT_AMOUNT) {
            revert TotalSupplyMinted();
        }

        IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
    }

    // @notice To check how many tokens left to mint 
    function checkRemainingTokens(address minter) public view returns (uint256) {
        uint256 remainingTokens = MAX_AMOUNT - balanceOf(minter, WATER_SAMURAI_TOKEN_ID);
        return remainingTokens;
    }

    /* WHITELIST MANAGING FUNCTIONS */
    function isMinterWhitelisted(address minter) external view returns (bool) {
        return whitelisted[minter];
    }

    // use this format to add array in Remix
    // ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db"]

    function addToWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _addToWhitelist(accounts[i]);
        }
    }

    function _addToWhitelist(address account) internal {
        whitelisted[account] = true;
    }

    function removeFromWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _removeFromWhitelist(accounts[i]);
        }
    }

    function _removeFromWhitelist(address account) internal {
        whitelisted[account] = false;
    }

    /* ROYALTY MANAGING FUNCTIONS */
    function setDefaultRoyalty(address receiver) public onlyOwner {
        _setDefaultRoyalty(receiver, ROYALTY_FEE);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(address receiver) public onlyOwner {
        _setTokenRoyalty(WATER_SAMURAI_TOKEN_ID, receiver, ROYALTY_FEE);
    }

    function resetTokenRoyalty() public onlyOwner {
        _resetTokenRoyalty(WATER_SAMURAI_TOKEN_ID);
    }

    /* PAUSE MINT MANAGING FUNCTIONS */
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Couldn't send funds to owner");
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
            tokenId == WATER_SAMURAI_TOKEN_ID,
            'ERC1155Metadata: URI query for nonexistent token'
        );
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), '.json')
            );
    }

    function contractURI() public view returns (string memory) {
        return _contractURI; // see: https://docs.opensea.io/docs/contract-level-metadata and set
    }

    receive() external payable nonReentrant {}
}
