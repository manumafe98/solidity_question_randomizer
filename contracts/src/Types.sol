// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Types {
    struct Question {
        uint256 id;
        string question;
        string[] options;
        string answer;
    }
}
