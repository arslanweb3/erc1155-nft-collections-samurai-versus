// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract Token {
    constructor () ERC1155("https://example.com/api/item/{id}.json") {}

    
}
