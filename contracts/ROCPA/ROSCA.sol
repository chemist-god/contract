// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SusuROSCA {
    // State Variables
    address[] public members;
    uint public contributionAmount;
    uint public currentRound;
    uint public totalRounds;
    uint public roundDeadline;
    uint public constant roundDuration = 7 days;
    uint public constant gracePeriod = 1 days;
    
    // Mappings
    mapping(address => bool) public isMember;
    mapping(address => bool) public hasReceived;
    mapping(uint => mapping(address => bool)) public roundContributions;
    mapping(address => uint) public lastContributionTime;
    mapping(address => bool) public emergencyVotes;
    mapping(uint => address) public roundToRecipient;
    
    // Counters
    uint public emergencyVoteCount;
    uint public minContributorsPerRound;

    // Events
    event ContributionMade(address indexed member, uint amount, uint round);
    event DistributionMade(address indexed recipient, uint amount, uint round);
    event EmergencyVoted(address indexed member);
    event EmergencyExecuted(address indexed recipient, uint amount);
    event RoundAdvanced(uint newRound, uint newDeadline);

    constructor(address[] memory _members, uint _contributionAmount) {
        require(_members.length > 1, "Need at least 2 members");
        members = _members;
        contributionAmount = _contributionAmount;
        totalRounds = _members.length;
        roundDeadline = block.timestamp + roundDuration;
        minContributorsPerRound = (_members.length * 2) / 3;
        
        for (uint i = 0; i < _members.length; i++) {
            isMember[_members[i]] = true;
            roundToRecipient[i] = _members[i];
        }
    }

    function contribute() external payable {
        require(isMember[msg.sender], "Not a member");
        require(!hasReceived[msg.sender], "Already received payout");
        require(msg.sender != roundToRecipient[currentRound], "Recipient cannot contribute");
        
        if (block.timestamp > roundDeadline) {
            uint lateFee = (contributionAmount * 10) / 100;
            require(msg.value == contributionAmount + lateFee, "Pay late fee");
        } else {
            require(msg.value == contributionAmount, "Incorrect amount");
        }

        roundContributions[currentRound][msg.sender] = true;
        lastContributionTime[msg.sender] = block.timestamp;
        
        emit ContributionMade(msg.sender, msg.value, currentRound);
    }

    function distributeRound() external {
        require(currentRound < totalRounds, "All rounds completed");
        require(block.timestamp >= roundDeadline, "Round not yet ended");
        require(block.timestamp <= roundDeadline + gracePeriod, "Grace period expired");
        
        uint contributorsCount = getContributorsForCurrentRound();
        require(contributorsCount >= minContributorsPerRound, "Not enough contributors");
        
        address recipient = roundToRecipient[currentRound];
        uint payoutAmount = contributionAmount * contributorsCount;
        require(address(this).balance >= payoutAmount, "Not enough funds");

        // State updates before transfer
        hasReceived[recipient] = true;
        currentRound++;
        roundDeadline = block.timestamp + roundDuration;
        emergencyVoteCount = 0;
        
        // Reset votes for new round
        for (uint i = 0; i < members.length; i++) {
            emergencyVotes[members[i]] = false;
        }

        payable(recipient).transfer(payoutAmount);
        
        emit DistributionMade(recipient, payoutAmount, currentRound - 1);
        emit RoundAdvanced(currentRound, roundDeadline);
    }

    function voteForEmergency() external {
        require(isMember[msg.sender], "Not a member");
        require(!emergencyVotes[msg.sender], "Already voted");
        emergencyVotes[msg.sender] = true;
        emergencyVoteCount++;
        
        emit EmergencyVoted(msg.sender);
    }

    function executeEmergency(address recipient) external {
        require(emergencyVoteCount > (members.length / 2), "Majority vote required");
        require(isMember[recipient], "Recipient must be a member");
        require(currentRound < totalRounds, "Already completed");
        
        uint contractBalance = address(this).balance;
        currentRound = totalRounds;
        
        // Clear all emergency votes
        for (uint i = 0; i < members.length; i++) {
            emergencyVotes[members[i]] = false;
        }
        
        payable(recipient).transfer(contractBalance);
        
        emit EmergencyExecuted(recipient, contractBalance);
    }

    // View Functions
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getContributorsForCurrentRound() public view returns (uint) {
        uint count;
        for (uint i = 0; i < members.length; i++) {
            if (roundContributions[currentRound][members[i]]) {
                count++;
            }
        }
        return count;
    }

    function isRoundReady() public view returns (bool) {
        return block.timestamp >= roundDeadline && 
               block.timestamp <= roundDeadline + gracePeriod &&
               getContributorsForCurrentRound() >= minContributorsPerRound;
    }
}