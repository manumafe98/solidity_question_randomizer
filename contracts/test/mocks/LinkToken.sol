// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BurnMintERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";

contract LinkToken is BurnMintERC677 {
    constructor() BurnMintERC677("ChainLink Token", "LINK", 18, 1e27) {}
}
