// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {QuestionRandomizer} from "../src/QuestionRandomizer.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "../script/Interactions.s.sol";

contract DeployQuestionRandomizer is Script {
    function run() external returns (QuestionRandomizer, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast();
        QuestionRandomizer questionRandomizer = new QuestionRandomizer(
            config.subscriptionId,
            config.vrfCoordinator,
            config.keyHash,
            config.callbackGasLimit,
            config.requestConfirmations,
            config.numWords
        );
        vm.stopBroadcast();

        addConsumer.addConsumer(address(questionRandomizer), config.vrfCoordinator, config.subscriptionId, config.account);
        return (questionRandomizer, helperConfig);
    }
}
