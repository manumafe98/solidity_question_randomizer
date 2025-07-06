// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {DeployQuestionRandomizer} from "../script/DeployQuestionRandomizer.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {QuestionRandomizer} from "../src/QuestionRandomizer.sol";
import {LinkToken} from "./mocks/LinkToken.sol";
import {CodeConstants} from "../script/CodeConstants.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Types} from "../src/Types.sol";

contract QuestionRandomizerTest is Test, CodeConstants {
    QuestionRandomizer questionRandomizer;
    HelperConfig helperConfig;

    uint256 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    address vrfCoordinator;
    LinkToken link;

    address public USER = makeAddr("user");
    uint256 public constant ETH_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    uint256 public constant QUESTION_ID = 1;
    string public constant QUESTION = "What is a smart contract?.";
    string[] public OPTIONS = ["A physical agreement that requires notarization.", "A type of blockchain that only records user credentials.", "A smart contract is an agreement that is deployed on a decentralized blockchain. Once deployed, it cannot be altered, and its terms are public.", "A manual contract that involves intermediaries."];
    string public constant ANSWER = "A smart contract is an agreement that is deployed on a decentralized blockchain. Once deployed, it cannot be altered, and its terms are public.";

    event QuestionAdded(uint256 indexed questionId, string question, string[] options, string answer);

    function setUp() external {
        DeployQuestionRandomizer deployer = new DeployQuestionRandomizer();
        (questionRandomizer, helperConfig) = deployer.run();

        vm.deal(USER, ETH_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        keyHash = config.keyHash;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinator = config.vrfCoordinator;
        link = LinkToken(config.link);

        vm.startPrank(config.account);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.grantMintRole(config.account);
            link.mint(config.account, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, LINK_BALANCE);
        }
        link.approve(vrfCoordinator, LINK_BALANCE);
        vm.stopPrank();
    }

    function testAddQuestion() external {
        vm.prank(USER);
        questionRandomizer.addQuestion(QUESTION, OPTIONS, ANSWER);

        Types.Question memory question = questionRandomizer.getQuestionById(1);

        assertEq(questionRandomizer.getTotalQuestions(), QUESTION_ID);
        assertEq(question.question, QUESTION);
        assertEq(question.options[0], OPTIONS[0]);
        assertEq(question.answer, ANSWER);
    }

    function testAddQuestionEmitsEvent() external {
        vm.prank(USER);
        vm.expectEmit();
        emit QuestionAdded(QUESTION_ID, QUESTION, OPTIONS, ANSWER);
        questionRandomizer.addQuestion(QUESTION, OPTIONS, ANSWER);
    }

    function testGetRequestConfirmations() external {
        vm.prank(USER);
        uint16 requestConfirmations = questionRandomizer.getRequestConfirmations();

        assertEq(requestConfirmations, REQUEST_CONFIRMATIONS);
    }

    function testGetNumWords() external {
        vm.prank(USER);
        uint32 numWords = questionRandomizer.getNumWords();

        assertEq(numWords, NUM_WORDS);
    }

    function testGetRandomNumberUpdatesRequestId() external {
        uint256 previousRequestId = questionRandomizer.getLastRequestId();

        vm.startPrank(msg.sender);
        questionRandomizer.addQuestion(QUESTION, OPTIONS, ANSWER);
        questionRandomizer.getRandomNumber();
        vm.stopPrank();

        uint256 currentRequestId = questionRandomizer.getLastRequestId();

        assertEq(previousRequestId, 0);
        assertEq(currentRequestId, 1);
    }

    function testGetRandomNumberIsFullfilled() external {
        vm.startPrank(msg.sender);
        questionRandomizer.addQuestion(QUESTION, OPTIONS, ANSWER);
        questionRandomizer.getRandomNumber();
        vm.stopPrank();

        uint256 requestId = questionRandomizer.getLastRequestId();

        uint256 randomNumberBeforeFullFill = questionRandomizer.getRandomNumberByRequestId(requestId);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(questionRandomizer));
        uint256 randomNumberAfterFullFill = questionRandomizer.getRandomNumberByRequestId(requestId);
        
        assertEq(randomNumberBeforeFullFill, 0);
        assert(randomNumberAfterFullFill != 0);
    }

    function testGetRandomQuestion() external {
        vm.startPrank(msg.sender);
        questionRandomizer.addQuestion(QUESTION, OPTIONS, ANSWER);
        questionRandomizer.getRandomNumber();
        vm.stopPrank();

        uint256 requestId = questionRandomizer.getLastRequestId();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(questionRandomizer));

        vm.prank(USER);
        Types.Question memory question = questionRandomizer.getRandomQuestion();

        assertEq(question.question, QUESTION);
    }
}
