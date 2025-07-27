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

    
}
