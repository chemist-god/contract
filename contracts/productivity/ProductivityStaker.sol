// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract ProductivityStaker {
    struct Task {
        string description;
        uint256 deadline;
        uint256 rewardWeight;
        bool completed;
    }

    mapping(address => uint256) public stakes;
    mapping(address => Task[]) public tasks;
    mapping(address => uint256) public streaks;

    uint256 public totalStaked;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    }
