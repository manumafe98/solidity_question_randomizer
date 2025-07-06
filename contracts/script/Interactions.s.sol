// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DevOpsTools} from "@foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {CodeConstants} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId(block.chainid).vrfCoordinator;
        address account = helperConfig.getConfigByChainId(block.chainid).account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address _vrfCoordinator, address _account) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(_account);
        uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, _vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address _contractToAddToVrf, address _vrfCoordinator, uint256 _subId, address _account) public {
        console.log("Adding consumer contract: ", _contractToAddToVrf);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        console.log("account: ", _account);
        vm.startBroadcast(_account);
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(_subId, _contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address _mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        addConsumer(_mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("QuestionRandomizer", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

contract FundSubscription is CodeConstants, Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinator);
        }

        fundSubscription(vrfCoordinator, subId, link, account);
    }

    function fundSubscription(address _vrfCoordinator, uint256 _subId, address _link, address _account) public {
        console.log("Funding subscription: ", _subId);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(_account);
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(_link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(_link).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast(_account);
            LinkToken(_link).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
