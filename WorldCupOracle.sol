pragma solidity 0.8.17;

// SPDX-License-Identifier: UNLICENSED

contract WorldCupOracle {
    uint public latestAnswer = 1e18;
    string public name;
    address owner;

    constructor(string memory _name) {
        owner = msg.sender;
        name = _name;
    }

    function setAnswer(uint _latestAnswer) external {
        require(msg.sender == owner);
        require(_latestAnswer >= 1e18 && _latestAnswer <= 8e18);
        latestAnswer = _latestAnswer;
    }
}
