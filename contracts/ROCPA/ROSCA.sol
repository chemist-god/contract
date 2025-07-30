// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SusuROSCA {
    address[] public members;
    uint public contributionAmount;
    uint public currentRound;
    uint public totalRounds;
    uint public roundDeadline;
    uint public constant roundDuration = 7 days;
    
    mapping(address => bool) public isMember;
    mapping(address => bool) public hasReceived;
    mapping(address => uint) public contributions;
    mapping(address => uint) public lastContributionTime;
    mapping(address => bool) public emergencyVotes;
    uint public emergencyVoteCount;

    constructor(address[] memory _members, uint _contributionAmount) {
        require(_members.length > 1, "Need at least 2 members");
        members = _members;
        contributionAmount = _contributionAmount;
        totalRounds = _members.length;
        roundDeadline = block.timestamp + roundDuration;
        
        for (uint i = 0; i < _members.length; i++) {
            isMember[_members[i]] = true;
        }
    }

    function contribute() external payable {
        require(isMember[msg.sender], "Not a member");
        require(!hasReceived[msg.sender], "Already received payout");
        
        if (block.timestamp > roundDeadline) {
            uint lateFee = (contributionAmount * 10) / 100;
            require(msg.value == contributionAmount + lateFee, "Pay late fee");
        } else {
            require(msg.value == contributionAmount, "Incorrect amount");
        }

        contributions[msg.sender] += msg.value;
        lastContributionTime[msg.sender] = block.timestamp;
    }

    function distributeRound() external {
        require(currentRound < totalRounds, "All rounds completed");
        require(address(this).balance >= contributionAmount * members.length, "Not enough funds");
        require(block.timestamp >= roundDeadline, "Round not yet ended");

        address recipient = members[currentRound];
        payable(recipient).transfer(contributionAmount * members.length);
        
        hasReceived[recipient] = true;
        currentRound++;
        roundDeadline = block.timestamp + roundDuration;
        emergencyVoteCount = 0; // Reset emergency votes for new round
    }

    function voteForEmergency() external {
        require(isMember[msg.sender], "Not a member");
        require(!emergencyVotes[msg.sender], "Already voted");
        emergencyVotes[msg.sender] = true;
        emergencyVoteCount++;
    }

    function executeEmergency(address recipient) external {
        require(emergencyVoteCount > (members.length / 2), "Majority vote required");
        payable(recipient).transfer(address(this).balance);
        currentRound = totalRounds; // Terminate the Susu
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}