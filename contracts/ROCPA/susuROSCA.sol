// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SusuROSCA is ReentrancyGuard {
    // State Variables
    address[] public members;
    uint public contributionAmount;
    uint public currentRound;
    uint public totalRounds;
    uint public roundDeadline;
    uint public constant roundDuration = 7 days;
    uint public constant gracePeriod = 1 days;
    address public admin;
    
    // Mappings
    mapping(address => bool) public isMember;
    mapping(address => bool) public hasReceived;
    mapping(uint => mapping(address => bool)) public roundContributions;
    mapping(address => uint) public contributions;
    mapping(address => uint) public lastContributionTime;
    mapping(address => bool) public emergencyVotes;
    mapping(address => bool) public extensionVotes;
    mapping(uint => address) public roundToRecipient;
    
    // Structs
    struct Contribution {
        uint amount;
        uint timestamp;
        bool isLate;
    }
    
    mapping(uint => mapping(address => Contribution)) public contributionDetails;

    // Counters
    uint public emergencyVoteCount;
    uint public extensionVoteCount;
    uint public minContributorsPerRound;
    uint public proposedExtension;

    // Events
    event ContributionMade(address indexed member, uint amount, uint round, bool isLate);
    event DistributionMade(address indexed recipient, uint amount, uint round);
    event EmergencyVoted(address indexed member);
    event EmergencyExecuted(address indexed recipient, uint amount);
    event RoundAdvanced(uint newRound, uint newDeadline);
    event MemberReplaced(address oldMember, address newMember);
    event ExtensionProposed(uint additionalDays);
    event ExtensionApproved(uint newDeadline);

    constructor(address[] memory _members, uint _contributionAmount) {
        require(_members.length > 1, "Need at least 2 members");
        require(_contributionAmount > 0, "Contribution must be positive");
        
        members = _members;
        contributionAmount = _contributionAmount;
        totalRounds = _members.length;
        roundDeadline = block.timestamp + roundDuration;
        minContributorsPerRound = (_members.length * 2) / 3;
        admin = msg.sender;
        
        for (uint i = 0; i < _members.length; i++) {
            require(_members[i] != address(0), "Invalid member address");
            require(!isMember[_members[i]], "Duplicate member");
            
            isMember[_members[i]] = true;
            roundToRecipient[i] = _members[i];
        }
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member");
        _;
    }

    function contribute() external payable onlyMember nonReentrant {
        require(!hasReceived[msg.sender], "Already received payout");
        require(msg.sender != roundToRecipient[currentRound], "Recipient cannot contribute");
        require(msg.value > 0, "Must send some value");
        
        bool isLate = block.timestamp > roundDeadline;
        uint requiredAmount = isLate ? 
            contributionAmount + (contributionAmount * 10) / 100 : 
            contributionAmount;
            
        require(msg.value == requiredAmount, "Incorrect amount");

        roundContributions[currentRound][msg.sender] = true;
        contributions[msg.sender] += msg.value;
        lastContributionTime[msg.sender] = block.timestamp;
        
        contributionDetails[currentRound][msg.sender] = Contribution({
            amount: msg.value,
            timestamp: block.timestamp,
            isLate: isLate
        });
        
        emit ContributionMade(msg.sender, msg.value, currentRound, isLate);
        
        // Check if we can auto-advance
        if (isRoundReady()) {
            distributeRound();
        }
    }

    function distributeRound() public nonReentrant {
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
        
        // Reset all votes
        emergencyVoteCount = 0;
        extensionVoteCount = 0;
        proposedExtension = 0;
        
        for (uint i = 0; i < members.length; i++) {
            emergencyVotes[members[i]] = false;
            extensionVotes[members[i]] = false;
        }

        payable(recipient).transfer(payoutAmount);
        
        emit DistributionMade(recipient, payoutAmount, currentRound - 1);
        emit RoundAdvanced(currentRound, roundDeadline);
    }

    function voteForEmergency() external onlyMember {
        require(!emergencyVotes[msg.sender], "Already voted");
        emergencyVotes[msg.sender] = true;
        emergencyVoteCount++;
        
        emit EmergencyVoted(msg.sender);
        
        if (emergencyVoteCount > members.length / 2) {
            executeEmergency(msg.sender);
        }
    }

    function executeEmergency(address recipient) internal {
        require(isMember[recipient], "Recipient must be a member");
        require(currentRound < totalRounds, "Already completed");
        
        uint contractBalance = address(this).balance;
        currentRound = totalRounds;
        
        // Clear all votes
        for (uint i = 0; i < members.length; i++) {
            emergencyVotes[members[i]] = false;
            extensionVotes[members[i]] = false;
        }
        
        payable(recipient).transfer(contractBalance);
        
        emit EmergencyExecuted(recipient, contractBalance);
    }

    function proposeExtension(uint additionalDays) external onlyMember {
        require(additionalDays <= 7, "Max 7 day extension");
        require(block.timestamp > roundDeadline - 1 days, "Too early to propose");
        proposedExtension = additionalDays;
        extensionVoteCount = 0;
        
        emit ExtensionProposed(additionalDays);
    }

    function voteForExtension() external onlyMember {
        require(proposedExtension > 0, "No extension proposed");
        require(!extensionVotes[msg.sender], "Already voted");
        extensionVotes[msg.sender] = true;
        extensionVoteCount++;
        
        if (extensionVoteCount > members.length / 2) {
            roundDeadline += proposedExtension;
            emit ExtensionApproved(roundDeadline);
            proposedExtension = 0;
        }
    }

    function replaceMember(address oldMember, address newMember) external onlyMember {
        require(isMember[oldMember], "Old member not found");
        require(!isMember[newMember], "New member already exists");
        require(newMember != address(0), "Invalid new member");
        
        // Update members array
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == oldMember) {
                members[i] = newMember;
                break;
            }
        }
        
        // Update mappings
        isMember[oldMember] = false;
        isMember[newMember] = true;
        
        // Update recipient mapping for future rounds
        for (uint i = currentRound; i < totalRounds; i++) {
            if (roundToRecipient[i] == oldMember) {
                roundToRecipient[i] = newMember;
            }
        }
        
        emit MemberReplaced(oldMember, newMember);
    }

    // View Functions
    
}