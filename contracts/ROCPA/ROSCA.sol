// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SusuROSCA {
    address[] public members;
    uint public contributionAmount;
    uint public currentRound;
    uint public totalRounds;
    uint public roundDeadline; // New: Tracks when the current round ends
    uint public roundDuration = 7 days; // New: Round length (e.g., 7 days)
    mapping(uint => address) public roundToRecipient;
    mapping(address => bool) public hasReceived;
    mapping(address => uint) public contributions;
   mapping(address => uint) public lastContributionTime;

    constructor(address[] memory _members, uint _contributionAmount) {
        require(_members.length > 1, "Need at least 2 members");
        members = _members;
        contributionAmount = _contributionAmount;
        totalRounds = _members.length;
        roundDeadline = block.timestamp + roundDuration; // New: Set first deadline
    }

    function contribute() external payable {
        require(msg.value == contributionAmount, "Incorrect amount");
        require(!hasReceived[msg.sender], "Already received payout");
        contributions[msg.sender] += msg.value;
    }

    function distributeRound() external {
        require(currentRound < totalRounds, "All rounds completed");
        require(address(this).balance >= contributionAmount * members.length, "Not enough funds");
        require(block.timestamp >= roundDeadline, "Round not yet ended"); // New: Enforce deadline

        address recipient = members[currentRound];
        payable(recipient).transfer(contributionAmount * members.length);
        
        hasReceived[recipient] = true;
        currentRound++;
        roundDeadline = block.timestamp + roundDuration; // New: Reset deadline for next round
    }
    function contribute() external payable {
    require(!hasReceived[msg.sender], "Already received payout");
    
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}