// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";
import {IGenesisWaterSamurai} from "./IGenesisWaterSamurai.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";

// @title Collection of the first "historical" Fire Samurai. Lifetime royalties for minters. Airdrops & rewards for holders.
contract GenesisFireSamurai is ERC1155, ERC2981, IGenesisWaterSamurai, Ownable, ReentrancyGuard, Pausable {

    using SafeERC20 for IERC20;

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
    error ClaimNotAvailable();

    /* ****** */
    /* EVENTS */
    /* ****** */

    event MintedTokens(address minter, uint256 amount);
    event ClaimedTokens(address claimer, uint256 amount);
    event AddedMinterShares(address minter, uint256 shares);
    event SetContractAddress(address collection);
    
    /* ******* */
    /* STORAGE */
    /* ******* */

    string public name;
    string public symbol;

    // @notice To keep track of how many tokens have been minted and how many are left to be minted.
    uint256 public totalSupply = 0;

    // @notice This is the maximum amount that whitelisted minter can mint in total water and fire samurai tokens
    // For example: 3 water samurai tokens and 7 fire samurai tokens (or any proportion)
    uint256 public constant MAX_AMOUNT = 10;

    // @notice All minters can mint multiple tokens with 1 token ID (this is how the ERC115 standard works)
    uint256 public constant TOKEN_ID = 1;

    // @notice This is the maximum amount of tokens (samurais) that can be minted by all users
    uint256 public constant MAX_MINT_AMOUNT = 500;

    // @notice "royaltyFee" in basis point (= 7%)
    uint96 public constant ROYALTY_FEE = 700; 

    // @notice Mint price 15$ per 1 token (in BNB currency) 
    uint256 public mintPrice;

    // @notice Public mint price 20$ per 1 token (in BNB currency) 
    uint256 public publicMintPrice; 

    // @notice 15 free mint tokens are reserved in Genesis Fire Samurai Collection for particular users and each time someone claims free tokens -> 'freeMintAmount' count will decrease
    uint256 public freeMintAmount = 15;

    // @notice Whether whitelist mint stage = true or false. False by default
    bool public whitelistMintStage;

    // @notice Whether public mint stage = true or false. False by default
    bool public publicMintStage;

    // @notice Whether free mint tokens are reserved or not. True by default
    bool public freeMintTokensReserved = true;

    // @notice Whether default royalty is set or not. False by default
    bool public defaultRoyaltySet = false;

    // @notice Whether token royalty is set or not. False by default
    bool public tokenRoyaltySet = false;

    // @notice Whether whitelist mint price is set or not. False by default
    bool public mintPriceSet = false;

    // @notice Whether public mint price is set or not. False by default
    bool public publicMintPriceSet = false;

    // @notice "royaltyBalancer" smart-contract for receiving, managing and distributing royalty fee rewards
    // from secondary sales to initial minters 
    IRoyaltyBalancer public immutable royaltyBalancer;

    // @notice Genesis Water Samurai contract collection's address 
    IGenesisWaterSamurai public waterSamuraiContract; 

    // @notice This mapping is used to set whitelisted addresses
    mapping(address => bool) public whitelisted;

    // @notice These mappings are used to 1) set addresses that can mint few tokens for free, 
    // 2) set their amount of tokens they are eligibled and when someone claims tokens
    // 3) to keep of track of that action and in 'mintSamurai' function check 
    // that if user has already claimed then don't consider this free claimed amount and let him mint his max limit of 10 tokens for BNB
    mapping(address => bool) public freeMintEligibled;
    mapping(address => uint256) public amountEligibled;
    mapping(address => uint256) public claimedFreeMintTokens;

    // @notice This mapping is used to keep track 'amount' of tokens whitelisted address minted.
    // Claimed tokens for free not included in this mapping!
    mapping(address => uint256) public mintedAmount;

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor(IRoyaltyBalancer _royaltyBalancer) ERC1155("") {
        name = "Genesis Fire Samurai";
        symbol = "GFS";
        royaltyBalancer = IRoyaltyBalancer(_royaltyBalancer);
        setDefaultRoyalty(address(royaltyBalancer));
        setTokenRoyalty(address(royaltyBalancer));
    }

    /* *********** */
    /*  FUNCTIONS  */
    /* *********** */

    /* This 'mintSamurai' function mints new tokens. 
    The whole mint process can be divided into 3 stages:
        1) Only whitelisted minters that we set initially in 'addToWhitelist' function can mint tokens but the have maximum limit of 10 tokens (included both genesis water and fire samurai),
        we also have free mint tokens and they are reserved to be claimed for free
        Whitelisted minters pay 15$ (in BNB crypto currency) to mint 1 token. Total supply = 500. 

        2) Here we set 'public mint' and anyone can mint any amount of tokens they wish. 15 free mint tokens are reserved to be claimed for free.
        Minters pay 20$ (in BNB crypto currency) to mint 1 token.

        3) If free mint tokens weren't claimed for free or some amount was left then we can set 3 stage, 
        where we have 'public mint' and free mint tokens stop being reserved anymore. Tokens are supposed to be minted for 20$ (per 1 token).

    All minters are added to 'royaltyBalancer' contract state with their shares (1 minted token = 1 share), so that they would be able to claim their royalty fee rewards. */
    function mintSamurai(address to, uint256 amount) public payable nonReentrant whenNotPaused {

        // 1 stage -> only whitelisted minters can mint tokens. 15 free mint tokens are reserved to be claimed for free.
        if (whitelistMintStage == true && freeMintTokensReserved == true) {

            // Check that address 'to' is whitelisted
            require(whitelisted[to], "Can't mint tokens, address 'to' not whitelisted!");

            /* Check that 'to' doesn't have more tokens than 'MAX_AMOUNT' (included both genesis water and fire samurai)
            claimedFreeMintTokens[to] doesn't count because these tokens were claimed FOR FREE, whitelisted minter can mint maximum 'MAX_AMOUNT' tokens (free mint tokens are not included it this 'MAX_AMOUNT' limit)
            For example: 
                balanceOf(to, TOKEN_ID) = 1 (1 free claimed token);
                amount = 4;
                claimedFreeMintTokens[to] = 1 (1 free claimed token again);
                getWaterSamuraiMintedAmount(to) = 3;
                1 + 4 - 1 + 3 = 7 (because 'balanceOf() - claimedFreeMintTokens[]]' = 0)
            Final amount must be less than 'MAX_AMOUNT', otherwise it will revert with 'MintLimitReached()' */
            
            if (balanceOf(to, TOKEN_ID) + amount - claimedFreeMintTokens[to] + getWaterSamuraiMintedAmount(to) > MAX_AMOUNT) {
                revert MintLimitReached();
            }

            /* Check that 'MAX_AMOUNT' (10) - getWaterSamuraiMintedAmount() (for example = 3) >= 'amount' (user's input amount),
            otherwise it will throw an error */
            require(MAX_AMOUNT - getWaterSamuraiMintedAmount(to) >= amount, "Can't mint more tokens");

            // Check that user sent enough BNB for amount of tokens he wants to mints 
            require(msg.value >= (amount * mintPrice), "Not enough BNB sent. Check 'mintPrice'!");

            totalSupply += amount;

            /* If 'totalSupply' (say it's 490 now) > 'MAX_MINT_AMOUNT' (500) - freeMintAmount (15) --> (490 > 485),
            then it will revert with 'TotalSupplyMinted()', otherwise it's ok */
            if (totalSupply > MAX_MINT_AMOUNT - freeMintAmount) { 
                revert TotalSupplyMinted();
            }

            // Mint tokens. We don't need to pass any 'data' here so we just set ""
            _mint(to, TOKEN_ID, amount, "");

            /* This mapping is used to keep track 'amount' of tokens whitelisted address minted.
            Claimed tokens for free not included in this mapping! */
            mintedAmount[to] += amount;
            emit MintedTokens(to, amount);

            /* Adding minter to 'royaltyBalancer' contract state with his shares (1 minted token = 1 share), 
            so that he would be able to claim his royalty fee rewards later */
            IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
            emit AddedMinterShares(to, amount);
        }

        // 2 stage -> here we set 'public mint' and anyone can mint any amount of tokens they wish. 15 free mint tokens are reserved to be claimed for free.
        if (publicMintStage == true && freeMintTokensReserved == true) {

            // Check that user sent enough BNB for amount of tokens he wants to mints 
            require(msg.value >= (amount * publicMintPrice), "Not enough BNB sent. Check 'publicMintPrice'!");

            totalSupply += amount;

            /* If 'totalSupply' (say it's 490 now) > 'MAX_MINT_AMOUNT' (500) - freeMintAmount (15) --> (490 > 485),
            then it will revert with 'TotalSupplyMinted()', otherwise it's ok */
            if (totalSupply > MAX_MINT_AMOUNT - freeMintAmount) { 
                revert TotalSupplyMinted();
            }

            // Mint tokens. We don't need to pass any 'data' here so we just set ""
            _mint(to, TOKEN_ID, amount, "");
            emit MintedTokens(to, amount);

            /* Adding minter to 'royaltyBalancer' contract state with his shares (1 minted token = 1 share), 
            so that he would be able to claim his royalty fee rewards later */
            IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
            emit AddedMinterShares(to, amount);
        }

        /* 3 stage -> if free mint tokens weren't claimed for free or some amount was left then we can set 3 stage, 
        where we have 'public mint' and free mint tokens stop being reserved anymore. */
        if (publicMintStage == true && freeMintTokensReserved == false) {

            // Check that 'freeMintAmount' is greater than 0, can't be below
            require(freeMintAmount > 0, "All free mint tokens were claimed"); 

            // Check that user sent enough BNB for amount of tokens he wants to mints 
            require(msg.value >= (amount * publicMintPrice), "Not enough BNB sent. Check 'publicMintPrice'!");

            totalSupply += amount;
            freeMintAmount -= amount;

            /* If 'totalSupply' (say it's 501 now) > 'MAX_MINT_AMOUNT' (500), then it will revert with 'TotalSupplyMinted()', otherwise it's ok.
            That is 'totalSupply' can't be greater than 500 */
            if (totalSupply > MAX_MINT_AMOUNT) { 
                revert TotalSupplyMinted();
            }

            // Mint tokens. We don't need to pass any 'data' here so we just set ""
            _mint(to, TOKEN_ID, amount, "");
            emit MintedTokens(to, amount);

            /* Adding minter to 'royaltyBalancer' contract state with his shares (1 minted token = 1 share), 
            so that he would be able to claim his royalty fee rewards later */
            IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
            emit AddedMinterShares(to, amount);
        }
    }

    /* This 'claimFreeTokens' function allows particular users to mint for free (or claim) tokens. Only 'freeMintEligibled' addresses can claim tokens. 
    All minters are added to 'royaltyBalancer' contract state with their shares (1 minted token = 1 share), so that they would be able to claim their royalty fee rewards. */
    function claimFreeTokens(address to, uint256 amount) public payable nonReentrant whenNotPaused {
        // If 15 free mint tokens are reserved for users (= true) then they can claim these tokens, otherwise it will revert with 'ClaimNotAvailable()' error 
        if (freeMintTokensReserved == true) {

            // Check that address 'to' is free mint eligibled
            require(freeMintEligibled[to], "Can't claim free tokens for 'to' address, not eligibled!");

            // Can't mint more 'amount' of tokens than address 'to' eligibled
            if (amount > amountEligibled[to]) {
                revert ExceededFreeMintAmount();
            }

            // Check that 'freeMintAmount' is greater than 0, can't be below
            require(freeMintAmount > 0, "All free mint tokens were claimed"); 

            // Mint tokens. We don't need to pass any 'data' here so we just set ""
            _mint(to, TOKEN_ID, amount, "");
            emit MintedTokens(to, amount);

            totalSupply += amount;
            claimedFreeMintTokens[to] += amount; 
            freeMintAmount -= amount;

            // Additional check that 'to' can't mint more tokens than eligibled
            require(claimedFreeMintTokens[to] <= amountEligibled[to], "You can't claim more tokens than you are eligibled"); 

            emit ClaimedTokens(to, amount);

            /* Adding minter to 'royaltyBalancer' contract state with his shares (1 minted token = 1 share), 
            so that he would be able to claim his royalty fee rewards later */
            IRoyaltyBalancer(royaltyBalancer).addMinterShare(to, amount);
            emit AddedMinterShares(to, amount);
        } else {
            revert ClaimNotAvailable();
        }
    }

    // ********* CONTRACT'S STATE MANAGING FUNCTIONS ********* //

    // @notice Allows owner() to set mint price and can't be reset anymore
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        require(mintPriceSet == false, "Mint price was already set");
        mintPrice = _mintPrice;
        mintPriceSet = true;
    }

    // @notice Allows owner() to set public mint price and can't be reset anymore
    function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner {
        require(publicMintPriceSet == false, "Public mint price was already set");
        publicMintPrice = _publicMintPrice;
        publicMintPriceSet = true;    
    }

    // @notice Owner() calls 'setWhitelistMintStage' function to set 1 mint stage 
    function setWhitelistMintStage() public onlyOwner {
        whitelistMintStage = true;
        publicMintStage = false;
    }

    // @notice Owner() calls 'setPublicMintStage' function to set 2 mint stage 
    function setPublicMintStage() public onlyOwner {
        whitelistMintStage = false;
        publicMintStage = true;
    }

    // @notice Owner() calls 'releaseReservedTokens' function to set 3 mint stage 
    function releaseReservedTokens() public onlyOwner {
        freeMintTokensReserved = false;
    }

    // @notice Owner() calls 'reserveFreeMintTokens' function to reserve tokens again
    function reserveFreeMintTokens() public onlyOwner {
        freeMintTokensReserved = true;
    }

    // @notice Owner() calls 'setContractAddress' function to set Genesis Water Samurai contract collection's address
    function setContractAddress(address collection) public onlyOwner {
        waterSamuraiContract = IGenesisWaterSamurai(collection);
        emit SetContractAddress(collection);
    }

    // @notice Owner() calls 'addToFreeMintList' function to add addresses in free mint list mapping in loop
    function addToFreeMintList(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {

        if (accounts.length != amounts.length) {
            revert LengthNotIdentical();
        }

        for (uint i; i < accounts.length; i++) {
            _addToFreeMintList(accounts[i], amounts[i]);
        }
    }

    // @notice Owner() calls 'addToWhitelist' function to add addresses in whitelist mapping in loop
    function addToWhitelist(address[] calldata accounts) public onlyOwner {
    
        for (uint256 i; i < accounts.length; i++) {
            _addToWhitelist(accounts[i]);
        }
    }

    // @notice Owner() calls 'addToWhitelist' function to remove addresses from whitelist mapping in loop
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

    // @notice To check if whitelist mint stage is available (front-end helpers)
    function checkWhitelistMintAvailable() public view returns (bool) {
        return whitelistMintStage;
    }

    // @notice To check if public mint stage is available (front-end helpers)
    function checkPublicMintAvailable() public view returns (bool) {
        return publicMintStage; 
    }

    // @notice To check if free mint tokens are reserved or not (front-end helpers)
    function checkFreeMintTokensReserved() public view returns (bool) {
        return freeMintTokensReserved;
    }

    // @notice To check if minter's address is eligibled to mint/claim free tokens (front-end helpers)
    function isFreeMintEligibled(address minter) external view returns (bool, uint256) {
        return (freeMintEligibled[minter], amountEligibled[minter]);
    }

    // @notice To check if minter's address whitelisted (front-end helpers)
    function isMinterWhitelisted(address minter) external view returns (bool) {
        return whitelisted[minter];
    }

    // @notice Returns amount of Genesis Fire Samurai tokens whitelisted address has minted
    function getMintedAmount(address minter) public view returns (uint256) {
        return mintedAmount[minter];
    }

    /* Returns amount of Genesis Water Samurai tokens whitelisted address has minted in another contract
    This function will be used to ensure that each whitelisted minter can mint max 10 tokens (whether water or fire samurai)
    For example: 3 water samurai tokens and 7 fire samurai tokens (or any proportion) */
    function getWaterSamuraiMintedAmount(address minter) public view returns (uint256) {
        uint256 amount = waterSamuraiContract.getMintedAmount(minter);
        return amount;
    }

    // @notice To check how many tokens left to mint (+ also front-end helpers)
    function checkRemainingTokens(address minter) external view returns (uint256) {
        uint256 remainingTokens = MAX_AMOUNT + claimedFreeMintTokens[minter] - getWaterSamuraiMintedAmount(minter) - balanceOf(minter, TOKEN_ID);
        return remainingTokens;
    }

    // @notice To check how many free tokens some address minted (or claimed) (front-end helpers)
    function checkFreeMintedTokens(address minter) external view returns (uint256) {
        return claimedFreeMintTokens[minter];
    }

    // @notice To check how many free tokens are available to mint (or claim) (front-end helpers)
    function checkFreeMintAmountAvailable() external view returns (uint256) {
        return freeMintAmount;
    }

    function isApprovedForAll(address _owner, address _operator) 
        public
        view
        override
        returns (bool isOperator)
    {
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId); 
    }

    function uri(uint256 tokenId) public pure override returns (string memory) {
        if (tokenId == TOKEN_ID) {
            return "ipfs://QmPaUuJQAbTF3FveGkgqbfj32dH9nWq27V1o9QZc6tSRGx/GenesisFireSamurai.json";
        } else {
            return "ipfs://QmPaUuJQAbTF3FveGkgqbfj32dH9nWq27V1o9QZc6tSRGx/GenesisFireSamurai.json";
        }
    }

    // ********* ROYALTY MANAGING FUNCTIONS ********* //

    // @notice Allows owner() to set default address for royalty receiving for this contract's collection
    function setDefaultRoyalty(address receiver) public onlyOwner {
        require(defaultRoyaltySet == false, "Default royalty was already set");
        _setDefaultRoyalty(receiver, ROYALTY_FEE);
        defaultRoyaltySet = true;
    }

    // @notice Allows owner() to delete default address
    function deleteDefaultRoyalty() public onlyOwner {
        require(defaultRoyaltySet == true, "Default royalty wasn't set");
        _deleteDefaultRoyalty();
        defaultRoyaltySet = false;
    }

    // @notice Allows owner() to set address for royalty receiving.
    function setTokenRoyalty(address receiver) public onlyOwner {
        require(tokenRoyaltySet == false, "Token royalty was already set");
        _setTokenRoyalty(TOKEN_ID, receiver, ROYALTY_FEE);
        tokenRoyaltySet = true;
    }

    // @notice Allows owner() to reset address for royalty receiving.
    function resetTokenRoyalty() public onlyOwner {
        require(tokenRoyaltySet == true, "Token royalty wasn't set");
        _resetTokenRoyalty(TOKEN_ID);
        tokenRoyaltySet = false;
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

    // @notice Allows owner() to withdraw BNB from this contract
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Couldn't send funds to owner");
    }

    // If some tokens will be sent to this contract owner() will be able to receive them 
    function removeTokensFromContract(IERC20 tokenContract) public onlyOwner {
        IERC20(tokenContract).safeTransfer(msg.sender, tokenContract.balanceOf(address(this)));
    }

    receive() external payable nonReentrant {}
}
