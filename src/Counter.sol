// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// TODO запросить список адрес для вайтлиста

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";

// import "./@openzeppelin/contracts/utils/ContextMixin.sol";

contract Collection is ERC1155, Ownable, ReentrancyGuard, ERC2981, Pausable {
    
    using Strings for string;

    uint256 private constant maxAmountPerID = 10;

    uint256 public waterSamuraiTokenID = 0;
    uint256 public fireSamuraiTokenID = 1;

    uint256 public constant maxAmountOfTokens = 1000;
    uint256 public constant maxAmountOfTokensPerTokenID = 500;

    uint256 public totalSupplyTokenID_1 = 0;
    uint256 public totalSupplyTokenID_2 = 0;

    // TODO узнать какая будет цена за минт 1 токена (самурая)
    uint256 public MINT_PRICE = 10 ether; // on polygon chain = 10 matic 
    uint256 public total_supply; // = 0 изначально

    uint96 private royaltyFee = 700; // 700 in basic point = 7%

    // TODO установить адреса контрактов распределения роялти
    IRoyaltyBalancer public royaltyBalancer1;
    IRoyaltyBalancer public royaltyBalancer2;

    mapping(address => bool) private _whitelist;

    modifier onlyWhitelisted() {
        require(_whitelist[msg.sender], "You are not whitelisted!");
        _;
    }

    // TODO узнать надо ли какие-то еще параметры в конструкторе и надо ли сменить string?
    constructor(address _royaltyBalancer1, address _royaltyBalancer2, address _addressOpenSea) ERC1155("https://example.com/api/item/{id}.json") {
        setRoyaltyBalancers(_royaltyBalancer1, _royaltyBalancer2);
        setApprovalForAll(_addressOpenSea, true); // эта фича позволит юзерам листит токены на маркетплейс без комиссии
        // TODO добавить адреса rarible, magic eden & другого маркетплейса?
    }

    function mintWaterSamurai(address to, uint256 amount, bytes memory data) public payable onlyWhitelisted {
        require(msg.value >= (amount * MINT_PRICE), "Not enough MATIC sent. Check mint price!");

        if (msg.value > (amount * MINT_PRICE)) {
            uint256 remainderAmount = msg.value - (amount * MINT_PRICE);
            (bool success, ) = to.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder MATIC to msg.sender");
        }

        require(amount <= maxAmountPerID, "You can't mint more than 10 tokens");
        require(balanceOf(to, waterSamuraiTokenID) <= maxAmountPerID, "Your minting limit exceeded");
        _mint(to, waterSamuraiTokenID, amount, "");
        totalSupplyTokenID_1 += amount;

        require(totalSupplyTokenID_1 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");

        IRoyaltyBalancer(royaltyBalancer1).addMinterShare(to, amount);

    }

    function mintFireSamurai(address to, uint256 amount, bytes memory data) public payable onlyWhitelisted {
        require(msg.value >= (amount * MINT_PRICE), "Not enough MATIC sent. Check mint price!");

        if (msg.value > (amount * MINT_PRICE)) {
            uint256 remainderAmount = msg.value - (amount * MINT_PRICE);
            (bool success, ) = to.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder MATIC to msg.sender");
        }

        require(amount <= maxAmountPerID, "You can't mint more than 10 tokens");
        require(balanceOf(to, fireSamuraiTokenID) <= maxAmountPerID, "Your minting limit exceeded");
        _mint(to, fireSamuraiTokenID, amount, "");

        totalSupplyTokenID_2 += amount;

        require(totalSupplyTokenID_2 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");

        IRoyaltyBalancer(royaltyBalancer2).addMinterShare(to, amount);
    }

    // TODO проверить чтобы работала без проблем

    function mintBatch(address to, uint256[] memory amounts, bytes memory data) public payable onlyWhitelisted {
        uint256[] memory amounts = new uint256[](2); 
        amounts[0];
        amounts[1];

        require(amounts[0] <= maxAmountPerID, "You can't mint more than 10 tokens");
        require(amounts[1] <= maxAmountPerID, "You can't mint more than 10 tokens");

        require(balanceOf(to, waterSamuraiTokenID) <= maxAmountPerID, "Your minting limit of water samurai exceeded");
        require(balanceOf(to, fireSamuraiTokenID) <= maxAmountPerID, "Your minting limit of fire samurai exceeded");

        uint256 amount = (amounts[0] + amounts[1]) * MINT_PRICE;

        require(msg.value >= amount, "Not enough MATIC sent. Check mint price!");

        if (msg.value > amount) {
            uint256 remainderAmount = msg.value - amount;
            (bool success, ) = to.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder MATIC to msg.sender");
        }

        uint256[] memory ids = new uint256[](2); 
        ids[0] = waterSamuraiTokenID;
        ids[1] = fireSamuraiTokenID;

        _mintBatch(to, ids, amounts, "");

        totalSupplyTokenID_1 += amounts[0];
        totalSupplyTokenID_2 += amounts[1];

        require(totalSupplyTokenID_1 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");
        require(totalSupplyTokenID_2 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");

        IRoyaltyBalancer(royaltyBalancer1).addMinterShare(to, amounts[0]);
        IRoyaltyBalancer(royaltyBalancer2).addMinterShare(to, amounts[1]);
    }

    function setRoyaltyBalancers(address _royaltyBalancer1, address _royaltyBalancer2) public onlyOwner {
        royaltyBalancer1 = IRoyaltyBalancer(_royaltyBalancer1);
        royaltyBalancer2 = IRoyaltyBalancer(_royaltyBalancer2);
    }

    function setDefaultRoyalty(address receiver) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFee);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, royaltyFee);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function addToWhitelistInLoop(address[] memory accounts) public onlyOwner {
        
        for (uint i = 0; i < accounts.length; i++) {
            addToWhitelist(accounts[i]);
        }
    }

    function addToWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // TODO убедиться что правильно работает

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return (
            interfaceId == type(ERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        require(tokenId == 0 || tokenId == 1, "ERC1155Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(contractURI(), Strings.toString(tokenId), ".json"));
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://example/"; // Contract-level metadata for ParkPics
    }

    receive() external payable {
        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "Couldn't transfer funds");
        
        // emit MaticReceived(msg.sender, msg.value);
    }
}
