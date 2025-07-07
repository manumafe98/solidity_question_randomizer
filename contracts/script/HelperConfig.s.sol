// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {CodeConstants} from "./CodeConstants.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint16 requestConfirmations;
        address vrfCoordinator;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(uint256 _chainId, NetworkConfig memory _networkConfig) public {
        networkConfigs[_chainId] = _networkConfig;
    }

    function getConfigByChainId(uint256 _chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[_chainId].vrfCoordinator != address(0)) {
            return networkConfigs[_chainId];
        } else if (_chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: SEPOLIA_SUBSCRIPTION_ID,
            keyHash: KEY_HASH,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            vrfCoordinator: SEPOLIA_VRF_COORDINATOR,
            link: SEPOLIA_LINK,
            account: SEPOLIA_VALID_ADDRESS
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast(FOUNDRY_DEFAULT_SENDER);
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        LinkToken link = new LinkToken();
        // https://github.com/Cyfrin/foundry-full-course-cu/discussions/2246
        // subId = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number) - 1 , address(this), currentSubNonce)));
        // causes arithmetic underflow delete -1 from blockhash(block.number) - 1 leaving -> blockhash(block.number)
        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId,
            keyHash: KEY_HASH,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            vrfCoordinator: address(vrfCoordinatorMock),
            link: address(link),
            account: FOUNDRY_DEFAULT_SENDER
        });

        vm.deal(localNetworkConfig.account, 100 ether);
        return localNetworkConfig;
    }
}
