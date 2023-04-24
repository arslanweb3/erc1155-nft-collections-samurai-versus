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
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";

contract Collection is ERC1155, Ownable, ReentrancyGuard, ERC2981, Pausable {
    using Strings for uint256;
    // using Address for address;
    // string internal _uriBase;

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
    constructor(IRoyaltyBalancer _royaltyBalancer1, IRoyaltyBalancer _royaltyBalancer2 /* string memory uri_ */) ERC1155("https://example.com/api/item/{id}.json") {
        setRoyaltyBalancers(_royaltyBalancer1, _royaltyBalancer2);
        _setDefaultRoyalty(address(this), royaltyFee); // to split royaltioes between balancers if marketplace cannot get royalty info
        _setTokenRoyalty(0, address(royaltyBalancer1), royaltyFee);
        _setTokenRoyalty(1, address(royaltyBalancer2), royaltyFee);
        /* 
        p.s. пока не обращай внимание на это, позже передалаю

        @dev OpenSea whitelisting. 
        эта фича позволит юзерам листит токены на маркетплейс без комиссии
        TODO добавить адреса rarible, magic eden & другого маркетплейса?
        _uriBase = "ipfs://bafybeicvbipj7n6zkphi7u5tu4gmu7oubi7nt5s2fjvkzxn7ggr4fjv2jy/"; // IPFS base for ParkPics collection 
        */

    }

    function mintWaterSamurai(uint256 amount) public payable onlyWhitelisted nonReentrant {
        require(msg.value >= (amount * MINT_PRICE), "Not enough MATIC sent. Check mint price!");

        if (msg.value > (amount * MINT_PRICE)) {
            uint256 remainderAmount = msg.value - (amount * MINT_PRICE);
            (bool success, ) = msg.sender.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder MATIC to msg.sender");
        }

        require(amount <= maxAmountPerID, "You can't mint more than 10 tokens");
        require(checkBalance(msg.sender, waterSamuraiTokenID) <= maxAmountPerID, "Your minting limit exceeded");
        _mint(msg.sender, waterSamuraiTokenID, amount, "");
        totalSupplyTokenID_1 += amount;

        require(totalSupplyTokenID_1 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");

        IRoyaltyBalancer(royaltyBalancer1).addMinterShare(msg.sender, amount);
    }

    function mintFireSamurai(uint256 amount) public payable onlyWhitelisted nonReentrant {
        require(msg.value >= (amount * MINT_PRICE), "Not enough MATIC sent. Check mint price!");

        if (msg.value > (amount * MINT_PRICE)) {
            uint256 remainderAmount = msg.value - (amount * MINT_PRICE);
            (bool success, ) = msg.sender.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder MATIC to msg.sender");
        }

        require(amount <= maxAmountPerID, "You can't mint more than 10 tokens");
        require(checkBalance(msg.sender, fireSamuraiTokenID) <= maxAmountPerID, "Your minting limit exceeded");
        _mint(msg.sender, fireSamuraiTokenID, amount, "");

        totalSupplyTokenID_2 += amount;

        require(totalSupplyTokenID_2 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");

        IRoyaltyBalancer(royaltyBalancer2).addMinterShare(msg.sender, amount);
    }

    // TODO проверить чтобы работала без проблем

    function mintBatch(uint256[] memory amounts) public payable onlyWhitelisted nonReentrant {

        /* надо ли это?
        uint256[] memory amounts = new uint256[](2); 
        */

        amounts[0];
        amounts[1];

        require(amounts[0] <= maxAmountPerID, "You can't mint more than 10 tokens");
        require(amounts[1] <= maxAmountPerID, "You can't mint more than 10 tokens");

        require(checkBalance(msg.sender, waterSamuraiTokenID) <= maxAmountPerID, "Your minting limit of water samurai exceeded");
        require(checkBalance(msg.sender, fireSamuraiTokenID) <= maxAmountPerID, "Your minting limit of fire samurai exceeded");

        uint256 amount = (amounts[0] + amounts[1]) * MINT_PRICE;

        require(msg.value >= amount, "Not enough MATIC sent. Check mint price!");

        if (msg.value > amount) {
            uint256 remainderAmount = msg.value - amount;
            (bool success, ) = msg.sender.call{value: remainderAmount}("");
            require(success, "Couldn't send remainder MATIC to msg.sender");
        }

        uint256[] memory ids = new uint256[](2); 
        ids[0] = waterSamuraiTokenID;
        ids[1] = fireSamuraiTokenID;

        _mintBatch(msg.sender, ids, amounts, "");

        totalSupplyTokenID_1 += amounts[0];
        totalSupplyTokenID_2 += amounts[1];

        require(totalSupplyTokenID_1 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");
        require(totalSupplyTokenID_2 <= maxAmountOfTokensPerTokenID, "Total supply exceeded: max 500 tokens per ID");

        IRoyaltyBalancer(royaltyBalancer1).addMinterShare(msg.sender, amounts[0]);
        IRoyaltyBalancer(royaltyBalancer2).addMinterShare(msg.sender, amounts[1]);
    }

    function checkApprovedForAll(address account, address operator) public view returns (bool) {
        // TODO уточнить какой будет адрес вместо "0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101" на полигоне

        if(operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)){
            return true;
        }

        /* if(operator == address(rarible)){
            return true;
        }

        if(operator == address(magicEden)){
            return true;
        } */

        return isApprovedForAll(account, operator);
    }

    function checkBalance(address account, uint256 id) public view returns (uint256) {
        require(id == 0 || id == 1, "You query for nonexistent token ID");
        return balanceOf(account, id);
    }

    function setRoyaltyBalancers(IRoyaltyBalancer _royaltyBalancer1, IRoyaltyBalancer _royaltyBalancer2) public onlyOwner {
        royaltyBalancer1 = _royaltyBalancer1;
        royaltyBalancer2 = _royaltyBalancer2;
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

    function checkIfWhitelisted(address _minter) public view returns (bool) {
        return _whitelist[_minter];
    }

    /* позже доделаю, надо подтверждения будем ли использовать этот функционал в контракте */

    /* function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    } */

    // TODO убедиться что правильно работает на уровне тестов
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
        return string(abi.encodePacked(contractURI(), tokenId.toString(), ".json"));
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://example/"; // Contract-level metadata for ParkPics
    }


    /* 
    Может произойти такое что один из 3 маркетплейсов сможет отправить роялти на адрес по дефолту (адрес коллекции), 
    в этом случае мы сделаем следующее:
    В контракте коллекции есть функция receive() которая принимает matic. 
    В этой функции будет проверка что если у того кто вызвал эту функцию (отправил средства в контракт) размер поля code > 0, 
    то это будет значит что вызывающий функцию является смарт-контрактом и сумма которую он отправляет (роялти) будет делиться на 2 части 
    и отправляться в 2 смарт-контракта для получения/распределения средств минтерам. 
    Если же поле code = 0, то значит что это обычный адрес и минтер будет минтить себе токены и отправлять в контракт matic, 
    все полученные средства будут сразу же в одной транзакции отправляться владельцу контракта на его кошелек через receive() функцию.
    */

    receive() external payable {
        uint256 amount = msg.value / 2;
        (bool successCall1, ) = address(royaltyBalancer1).call{value: amount}("");
        (bool successCall2, ) = address(royaltyBalancer2).call{value: msg.value - amount}("");
        require(successCall1 && successCall2, "Couldn't send MATIC to one of two royalty balancers");
    }
}
