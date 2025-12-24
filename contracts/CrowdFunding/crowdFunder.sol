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

    // ----- FUNDING STATE MANAGEMENT -----

    /// @notice Sponsor closes funding after deadline or once goal is reached.
    function closeFunding() external onlySponsor {
        require(!fundingClosed, "Already closed");
        require(
            block.timestamp > deadline || totalInvested >= fundingGoal,
            "Too early to close"
        );

        fundingClosed = true;
        goalReached = (totalInvested >= fundingGoal);

        emit FundingClosed(goalReached, totalInvested);
    }

    /// @notice Sponsor withdraws raised capital if goal reached and funding closed.
    function withdrawToSponsor(uint256 amount) external onlySponsor {
        require(fundingClosed, "Funding not closed");
        require(goalReached, "Goal not reached");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool ok, ) = sponsor.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    // ----- REFUND & RETURNS LOGIC -----

    /// @notice Investors can claim refund if goal not reached after funding is closed.
    function claimRefund() external {
        require(fundingClosed, "Funding not closed");
        require(!goalReached, "Goal was reached, no refunds");
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to refund");

        balances[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Refund failed");

        emit RefundClaimed(msg.sender, amount);
    }

    /// @notice Sponsor deposits ETH to distribute returns proportionally to each investor.
    /// @dev Call this after the property generates profit (off-chain).
    function distributeReturns() external payable onlySponsor {
        require(goalReached, "Goal not reached");
        require(fundingClosed, "Funding not closed");
        require(msg.value > 0, "No ETH provided");

        uint256 totalAmount = msg.value;
        uint256 length = investors.length;

        // Distribute proportionally to each investor according to share = balance / totalInvested
        for (uint256 i = 0; i < length; i++) {
            address investor = investors[i];
            uint256 invested = balances[investor];
            if (invested == 0) continue;

            uint256 share = (totalAmount * invested) / totalInvested;
            if (share > 0) {
                (bool ok, ) = investor.call{value: share}("");
                require(ok, "Return transfer failed");
            }
        }

        emit ReturnsDistributed(totalAmount);
    }

    // ----- VIEW HELPERS -----

    function getInvestors() external view returns (address[] memory) {
        return investors;
    }

    function getInvestorShare(address investor) external view returns (uint256) {
        if (totalInvested == 0) return 0;
        return (balances[investor] * 1e18) / totalInvested; // scaled fraction
    }
}
