// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SUSURotationalFund {
    struct Member {
        address addr;
        bool hasReceived;
    }

    address public organizer;
    uint256 public contributionAmount;
    uint256 public payoutInterval; // e.g., 30 days
    uint256 public currentRound;

    Member[] public members;
    mapping(address => uint256) public contributions;
    uint256 public totalContributed;
    uint256 public lastPayoutTime;

    constructor(uint256 _amount, uint256 _interval) {
        organizer = msg.sender;
        contributionAmount = _amount;
        payoutInterval = _interval;
        currentRound = 0;
        lastPayoutTime = block.timestamp;
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Not authorized");
        _;
    }

    function joinSUSU() external {
        require(members.length < 10, "Max group size reached");
        require(contributions[msg.sender] == 0, "Already joined");
        members.push(Member(msg.sender, false));
    }

    function contribute() external payable {
        require(msg.value == contributionAmount, "Incorrect amount");
        require(contributions[msg.sender] == 0, "Already contributed");
        contributions[msg.sender] = msg.value;
        totalContributed += msg.value;
    }

    function payout() external {
        require(block.timestamp >= lastPayoutTime + payoutInterval, "Not time yet");
        require(members.length > currentRound, "No recipient available");

        address payable recipient = payable(members[currentRound].addr);
        require(!members[currentRound].hasReceived, "Already paid");

        recipient.transfer(totalContributed);
        members[currentRound].hasReceived = true;

        // Reset for next round
        totalContributed = 0;
        for (uint i = 0; i < members.length; i++) {
            contributions[members[i].addr] = 0;
        }

        currentRound++;
        lastPayoutTime = block.timestamp;
    }

    
}
