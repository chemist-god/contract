// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract ProductivityStaker {
    struct Task {
        string description;
        uint256 deadline;
        uint256 rewardWeight;
        bool completed;
        bool missed;
    }

    mapping(address => uint256) public stakes;
    mapping(address => Task[]) public tasks;
    mapping(address => uint256) public streaks;
    mapping(address => uint256) public completedTasks;
    mapping(address => uint256) public missedTasks;

    uint256 public totalStaked;
    address public owner;

    event Staked(address indexed user, uint256 amount);
    event TaskCreated(address indexed user, uint256 taskId);
    event TaskUpdated(address indexed user, uint256 taskId);
    event TaskDeleted(address indexed user, uint256 taskId);
    event TaskCompleted(address indexed user, uint256 taskId, uint256 reward);
    event TaskMissed(address indexed user, uint256 taskId, uint256 penalty);

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
        emit Staked(msg.sender, amount);
    }
}