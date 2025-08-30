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

    // Create a new task
    function createTask(string memory description, uint256 deadline, uint256 rewardWeight) external {
        require(deadline > block.timestamp, "Deadline must be in future");
        require(rewardWeight > 0 && rewardWeight <= 100, "Invalid weight");

        tasks[msg.sender].push(Task(description, deadline, rewardWeight, false, false));
        emit TaskCreated(msg.sender, tasks[msg.sender].length - 1);
    }

    // Update a task
    function updateTask(uint256 taskId, string memory description, uint256 deadline, uint256 rewardWeight) external {
        require(taskId < tasks[msg.sender].length, "Invalid taskId");
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed && !task.missed, "Cannot update completed/missed task");

        task.description = description;
        task.deadline = deadline;
        task.rewardWeight = rewardWeight;
        emit TaskUpdated(msg.sender, taskId);
    }

    // Delete a task
    function deleteTask(uint256 taskId) external {
        require(taskId < tasks[msg.sender].length, "Invalid taskId");
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed && !task.missed, "Cannot delete completed/missed task");

        // Remove task by swapping with last and popping
        uint256 lastIndex = tasks[msg.sender].length - 1;
        if (taskId != lastIndex) {
            tasks[msg.sender][taskId] = tasks[msg.sender][lastIndex];
        }
        tasks[msg.sender].pop();
        emit TaskDeleted(msg.sender, taskId);
    }

    // Complete a task and earn rewards
    function completeTask(uint256 taskId) external {
        require(taskId < tasks[msg.sender].length, "Invalid taskId");
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed && !task.missed, "Already completed/missed");
        require(block.timestamp <= task.deadline, "Deadline passed");

        task.completed = true;
        streaks[msg.sender] += 1;
        completedTasks[msg.sender] += 1;

        uint256 reward = (stakes[msg.sender] * task.rewardWeight) / 100;
        payable(msg.sender).transfer(reward);
        stakes[msg.sender] -= reward;
        totalStaked -= reward;
        emit TaskCompleted(msg.sender, taskId, reward);
    }

    // Apply penalty for missed task
    function applyPenalty(uint256 taskId) external {
        require(taskId < tasks[msg.sender].length, "Invalid taskId");
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed && !task.missed, "Task already completed/missed");
        require(block.timestamp > task.deadline, "Deadline not passed");

        task.missed = true;
        missedTasks[msg.sender] += 1;

        uint256 penalty = (stakes[msg.sender] * task.rewardWeight) / 100;
        stakes[msg.sender] -= penalty;
        totalStaked -= penalty;
        emit TaskMissed(msg.sender, taskId, penalty);
        // Option: redirect to savingsPool, burn, or charity
    }

    
}