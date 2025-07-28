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

    function contribute() external payable {
        require(msg.value == contributionAmount, "Incorrect amount");
        require(!hasReceived[msg.sender], "Already received payout");
        contributions[msg.sender] += msg.value;
    }

    function distributeRound() external {
        require(currentRound < totalRounds, "All rounds completed");
        require(address(this).balance >= contributionAmount * members.length, "Not enough funds");

        address recipient = members[currentRound];
        payable(recipient).transfer(contributionAmount * members.length);
        
        hasReceived[recipient] = true;
        currentRound++;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}