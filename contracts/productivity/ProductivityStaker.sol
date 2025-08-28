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

    // Stake funds to activate productivity mode
    function stake(uint256 amount) external payable {
        require(msg.value == amount, "Incorrect ETH sent");
        require(amount > 0, "Stake must be positive");

        stakes[msg.sender] += amount;
        totalStaked += amount;
    }

    // Create a new task
    function createTask(string memory description, uint256 deadline, uint256 rewardWeight) external {
        require(deadline > block.timestamp, "Deadline must be in future");
        require(rewardWeight > 0 && rewardWeight <= 100, "Invalid weight");

        tasks[msg.sender].push(Task(description, deadline, rewardWeight, false));
    }

    
}
