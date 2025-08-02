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

   
}