// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Types} from "./Types.sol";

/**
 * @title Question Randomizer
 * @author Manuel Maxera
 * @notice This contract is designed for quiz-based applications to help people learn about smart contract development.
 * @notice It leverages Chainlink VRF to obtain verifiable random numbers, which are used to return random questions.
 */
contract QuestionRandomizer is VRFConsumerBaseV2Plus {
    error QuestionRandomizer__ToGenerateRandomNumbersFirstAddQuestions();

    /* State Variables */
    uint256 private s_totalQuestions;
    uint256 private s_lastRequestId;

    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private s_requestConfirmations;
    uint32 private s_numWords;

    mapping(uint256 => Types.Question) private s_questions;
    mapping(uint256 => uint256) private s_randomNumbers;

    /* Events */
    event QuestionAdded(uint256 indexed questionId, string question, string[] options, string answer);

    /**
     * @notice Initializes the contract with Chainlink VRF subscription details and configuration.
     * @param subscriptionId The Chainlink VRF subscription ID.
     * @param vrfCoordinator The address of the VRF Coordinator contract.
     * @param keyHash The key hash used to identify the VRF job.
     * @param callbackGasLimit The gas limit for the VRF callback.
     * @param requestConfirmations The number of confirmations to wait before fulfilling the request.
     * @param numWords The number of random words requested.
     */
    constructor(
        uint256 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;
    }

    /**
     * @notice Adds a new question to the contract.
     * @param _question The content of the question.
     * @param _options An array of possible answer options.
     * @param _answer The correct answer to the question.
     * @dev Emits a {QuestionAdded} event upon successful addition.
     */
    function addQuestion(string memory _question, string[] memory _options, string memory _answer) external {
        uint256 totalQuestions = s_totalQuestions += 1;

        s_questions[totalQuestions] =
            Types.Question({id: totalQuestions, question: _question, options: _options, answer: _answer});

        emit QuestionAdded(totalQuestions, _question, _options, _answer);
    }

    /**
     * @notice Requests random words from the Chainlink VRF oracle.
     * @dev Only callable by the contract owner. Saves the request ID for later use.
     */
    function getRandomNumber() external onlyOwner {
        if (s_totalQuestions == 0) {
            revert QuestionRandomizer__ToGenerateRandomNumbersFirstAddQuestions();
        }
        s_lastRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: s_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: s_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    /**
     * @notice Callback function that stores the random number associated with the request.
     * @dev Called by the VRF coordinator once the request is fulfilled.
     * @dev The random number is mapped to a question ID by taking:
     *      (_randomWords[0] % s_totalQuestions) + 1,
     *      ensuring the value is between 1 and s_totalQuestions (inclusive),
     *      which matches the question IDs starting from 1.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords The random numbers returned by Chainlink VRF.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        s_randomNumbers[_requestId] = (_randomWords[0] % s_totalQuestions) + 1;
    }

    /**
     * @notice Retrieves the last randomly selected question.
     * @return question The question object selected by the most recent VRF requested random number.
     */
    function getRandomQuestion() external view returns (Types.Question memory question) {
        question = s_questions[s_randomNumbers[s_lastRequestId]];
    }

    /**
     * @notice Gets the total number of questions currently stored.
     * @return totalQuestions The number of questions added to the contract.
     */
    function getTotalQuestions() external view returns (uint256 totalQuestions) {
        totalQuestions = s_totalQuestions;
    }

    /**
     * @notice Gets the last request ID used for fetching random words.
     * @return lastRequestId The most recent VRF request ID.
     */
    function getLastRequestId() external view returns (uint256 lastRequestId) {
        lastRequestId = s_lastRequestId;
    }

    /**
     * @notice Gets the number of random words configured to be requested from VRF.
     * @return numWords The number of random words per request.
     */
    function getNumWords() external view returns (uint32 numWords) {
        numWords = s_numWords;
    }

    /**
     * @notice Gets the number of request confirmations that were configured on VRF.
     * @return requestConfirmations The number of requests confirmations to be taken until returning the random words.
     */
    function getRequestConfirmations() external view returns (uint16 requestConfirmations) {
        requestConfirmations = s_requestConfirmations;
    }

    /**
     * @notice Retrieves a specific question by its ID.
     * @param _questionId The unique identifier of the question to retrieve.
     * @return question The Question struct associated with the provided ID.
     */
    function getQuestionById(uint256 _questionId) external view returns (Types.Question memory question) {
        question = s_questions[_questionId];
    }

    /**
     * @notice Retrieves a specific random number by its request id.
     * @param _requestId The unique identifier of the random number to retrieve.
     * @return randomNumber The random number associated with the provided request id.
     */
    function getRandomNumberByRequestId(uint256 _requestId) external view returns (uint256 randomNumber) {
        randomNumber = s_randomNumbers[_requestId];
    }
}
