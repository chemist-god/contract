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

    // Complete a task and earn rewards
    function completeTask(uint256 taskId) external {
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed, "Already completed");
        require(block.timestamp <= task.deadline, "Deadline passed");

        task.completed = true;
        streaks[msg.sender] += 1;

        uint256 reward = (stakes[msg.sender] * task.rewardWeight) / 100;
        payable(msg.sender).transfer(reward);
        stakes[msg.sender] -= reward;
        totalStaked -= reward;
    }

    // Apply penalty for missed task
    function applyPenalty(uint256 taskId) external {
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed, "Task already completed");
        require(block.timestamp > task.deadline, "Deadline not passed");

        uint256 penalty = (stakes[msg.sender] * task.rewardWeight) / 100;
        stakes[msg.sender] -= penalty;
        totalStaked -= penalty;
        // Option: redirect to savingsPool, burn, or charity
    }

    // View active tasks
    function getTasks() external view returns (Task[] memory) {
        return tasks[msg.sender];
    }

    // Emergency withdrawal (owner only)
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Fallback to accept ETH
    receive() external payable {}
}
