// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
contract QuestionRandomizer {
    struct Question {
        uint256 id;
        string question;
        string[] options;
        string answer;
    }

    uint256 private s_totalQuestions;

    mapping(uint256 => Question) private s_questions;

    event QuestionAdded(uint256 indexed questionId, string question, string[] options, string answer);

    function addQuestion(string memory _question, string[] memory _options, string memory _answer) external {
        uint256 totalQuestions = s_totalQuestions += 1;

        s_questions[totalQuestions] =
            Question({id: totalQuestions, question: _question, options: _options, answer: _answer});

        emit QuestionAdded(totalQuestions, _question, _options, _answer);
    }

    function getQuestionById(uint256 _questionId) external view returns (Question memory question) {
        question = s_questions[_questionId];
    }

    function getTotalQuestions() external view returns (uint256 totalQuestions) {
        totalQuestions = s_totalQuestions;
    }
}
