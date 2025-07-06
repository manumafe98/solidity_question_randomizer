// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;
    uint32 public constant CALLBACK_GAS_LIMIT = 500000;
    uint32 public constant NUM_WORDS = 1;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    bytes32 public constant KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    address public constant FOUNDRY_DEFAULT_SENDER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant SEPOLIA_VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    address public constant SEPOLIA_LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public constant SEPOLIA_VALID_ADDRESS = 0x8e1c7F6C8151fea4389a5c08FDa089d1629b4DDB;
}
