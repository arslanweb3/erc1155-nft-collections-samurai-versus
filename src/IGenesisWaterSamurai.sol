// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IGenesisWaterSamurai {
    function getMintedAmount(address minter) external view returns (uint256);
}
