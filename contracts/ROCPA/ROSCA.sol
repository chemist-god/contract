// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SusuROSCA {
    address[] public members;
    uint public contributionAmount;
    uint public currentRound;
    uint public totalRounds;
    mapping(uint => address) public roundToRecipient;
    mapping(address => bool) public hasReceived;
    mapping(address => uint) public contributions;

    constructor(address[] memory _members, uint _contributionAmount) {
        require(_members.length > 1, "Need at least 2 members");
        members = _members;
        contributionAmount = _contributionAmount;
        totalRounds = _members.length;
    }
}
