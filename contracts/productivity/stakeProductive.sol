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
    mapping(address => uint256) public lastCompletionTime; // To support real streaks
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
    event Withdrawn(address indexed user, uint256 amount);

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

        // Enforce max total active reward weight (100%)
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < tasks[msg.sender].length; i++) {
            Task storage t = tasks[msg.sender][i];
            if (!t.completed && !t.missed) {
                totalWeight += t.rewardWeight;
            }
        }
        require(totalWeight + rewardWeight <= 100, "Total active weights exceed 100%");

        tasks[msg.sender].push(Task(description, deadline, rewardWeight, false, false));
        emit TaskCreated(msg.sender, tasks[msg.sender].length - 1);
    }

    // Update a task
    function updateTask(uint256 taskId, string memory description, uint256 deadline, uint256 rewardWeight) external {
        require(taskId < tasks[msg.sender].length, "Invalid taskId");
        Task storage task = tasks[msg.sender][taskId];
        require(!task.completed && !task.missed, "Cannot update completed/missed task");

        // Recalculate total weight excluding current task
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < tasks[msg.sender].length; i++) {
            if (i == taskId) continue;
            Task storage t = tasks[msg.sender][i];
            if (!t.completed && !t.missed) {
                totalWeight += t.rewardWeight;
            }
        }
        require(totalWeight + rewardWeight <= 100, "Updated weights exceed 100%");

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
        completedTasks[msg.sender] += 1;

        // Improve streak: reset if gap > 24h, else increment
        if (block.timestamp > lastCompletionTime[msg.sender] + 24 hours) {
            streaks[msg.sender] = 1;
        } else {
            streaks[msg.sender] += 1;
        }
        lastCompletionTime[msg.sender] = block.timestamp;

        uint256 reward = (stakes[msg.sender] * task.rewardWeight) / 100;
        // Cap reward to available stake
        if (reward > stakes[msg.sender]) {
            reward = stakes[msg.sender];
        }

        // Update state before transfer (defense in depth)
        stakes[msg.sender] -= reward;
        totalStaked -= reward;

        // Use low-level call with success check (transfer is deprecated)
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "ETH transfer failed");

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
        // Cap penalty to available stake
        if (penalty > stakes[msg.sender]) {
            penalty = stakes[msg.sender];
        }

        stakes[msg.sender] -= penalty;
        totalStaked -= penalty;

        emit TaskMissed(msg.sender, taskId, penalty);

        // Optionally redirect penalty to charity, burn, or pool (not implemented here)
    }

    // Withdraw staked ETH (user can withdraw remaining balance)
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be positive");
        require(stakes[msg.sender] >= amount, "Insufficient stake");

        // Optional: prevent withdrawal if active tasks exist
        bool hasActiveTasks = false;
        for (uint256 i = 0; i < tasks[msg.sender].length; i++) {
            Task storage t = tasks[msg.sender][i];
            if (!t.completed && !t.missed) {
                hasActiveTasks = true;
                break;
            }
        }
        require(!hasActiveTasks, "Cannot withdraw with active tasks");

        stakes[msg.sender] -= amount;
        totalStaked -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // View active tasks
    function getTasks() external view returns (Task[] memory) {
        return tasks[msg.sender];
    }

    // Get staking info
    function getStakingInfo() external view returns (
        uint256 staked,
        uint256 streak,
        uint256 completed,
        uint256 missed
    ) {
        return (
            stakes[msg.sender],
            streaks[msg.sender],
            completedTasks[msg.sender],
            missedTasks[msg.sender]
        );
    }

    // Emergency withdrawal: only excess ETH (beyond totalStaked) can be withdrawn by owner
    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 excess = contractBalance > totalStaked ? contractBalance - totalStaked : 0;
        require(excess > 0, "No excess funds to withdraw");

        (bool success, ) = payable(owner).call{value: excess}("");
        require(success, "Emergency withdrawal failed");
    }

    // Restrict direct sends — only allow via `stake()` or accidental sends
    receive() external payable {
        // Allow ETH to be sent, but don't credit stake unless via `stake()`
        // This prevents accidental stake mismatches
    }

    // Fallback for non-payable function calls
    fallback() external payable {}
}