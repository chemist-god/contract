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
    mapping(uint => mapping(address => bool)) public roundContributions; // Track per-round contributions
    mapping(address => uint) public lastContributionTime;
    mapping(address => bool) public emergencyVotes;
    uint public emergencyVoteCount;
    uint public minContributorsPerRound; // Minimum contributors required to distribute

    constructor(address[] memory _members, uint _contributionAmount) {
        require(_members.length > 1, "Need at least 2 members");
        members = _members;
        contributionAmount = _contributionAmount;
        totalRounds = _members.length;
        roundDeadline = block.timestamp + roundDuration;
        minContributorsPerRound = (_members.length * 2) / 3; // e.g., 2/3 of members must contribute
        
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

        roundContributions[currentRound][msg.sender] = true;
        lastContributionTime[msg.sender] = block.timestamp;
    }

    function distributeRound() external {
        require(currentRound < totalRounds, "All rounds completed");
        require(block.timestamp >= roundDeadline, "Round not yet ended");
        
        // Check minimum contributors for this round
        uint contributorsCount;
        for (uint i = 0; i < members.length; i++) {
            if (roundContributions[currentRound][members[i]]) {
                contributorsCount++;
            }
        }
        require(contributorsCount >= minContributorsPerRound, "Not enough contributors");
        
        address recipient = members[currentRound];
        uint payoutAmount = contributionAmount * contributorsCount;
        require(address(this).balance >= payoutAmount, "Not enough funds");

        // Update state BEFORE transfer
        hasReceived[recipient] = true;
        currentRound++;
        roundDeadline = block.timestamp + roundDuration;
        emergencyVoteCount = 0;

        // Safe transfer last
        payable(recipient).transfer(payoutAmount);
    }

    function voteForEmergency() external {
        require(isMember[msg.sender], "Not a member");
        require(!emergencyVotes[msg.sender], "Already voted");
        emergencyVotes[msg.sender] = true;
        emergencyVoteCount++;
    }

    function executeEmergency(address recipient) external {
        require(emergencyVoteCount > (members.length / 2), "Majority vote required");
        currentRound = totalRounds; // Update state first
        payable(recipient).transfer(address(this).balance); // Then transfer
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getContributorsForCurrentRound() external view returns (uint) {
        uint count;
        for (uint i = 0; i < members.length; i++) {
            if (roundContributions[currentRound][members[i]]) {
                count++;
            }
        }
        return count;
    }
}