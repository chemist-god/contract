// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Real Estate Crowdfunding Contract
/// @notice Single-project crowdfunding: investors deposit, sponsor can close funding and distribute returns.
contract RealEstateCrowdfund {
    address public sponsor;          // Project owner / admin
    string public projectName;       // Name or short description
    uint256 public fundingGoal;      // Target amount in wei
    uint256 public deadline;         // Timestamp when funding ends
    bool public fundingClosed;       // True when sponsor closes funding
    bool public goalReached;         // True if total >= fundingGoal

    uint256 public totalInvested;    // Total amount invested

    mapping(address => uint256) public balances;  // investor => amount invested
    address[] public investors;                   // list of investor addresses

    event Invested(address indexed investor, uint256 amount);
    event FundingClosed(bool goalReached, uint256 total);
    event RefundClaimed(address indexed investor, uint256 amount);
    event ReturnsDistributed(uint256 totalAmount);

    modifier onlySponsor() {
        require(msg.sender == sponsor, "Not sponsor");
        _;
    }

    modifier fundingOpen() {
        require(!fundingClosed, "Funding closed");
        require(block.timestamp <= deadline, "Deadline passed");
        _;
    }

    constructor(
        string memory _projectName,
        uint256 _fundingGoal,
        uint256 _durationSeconds
    ) {
        require(_fundingGoal > 0, "Goal must be > 0");
        sponsor = msg.sender;
        projectName = _projectName;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _durationSeconds;
    }

    // ----- INVESTMENT LOGIC -----

    /// @notice Investors send ETH to participate in the project.
    function invest() external payable fundingOpen {
        require(msg.value > 0, "No ETH sent");

        if (balances[msg.sender] == 0) {
            investors.push(msg.sender);
        }

        balances[msg.sender] += msg.value;
        totalInvested += msg.value;

        emit Invested(msg.sender, msg.value);
    }

   
}
