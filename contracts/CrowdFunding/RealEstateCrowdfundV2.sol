// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Multi-Project Real Estate Crowdfunding with Project Tokens
/// @notice Admin can create multiple projects; investors buy project tokens using an ERC20 stablecoin.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract RealEstateCrowdfundV2 {
    // ----- ROLES & TOKENS -----
    address public admin;
    IERC20 public stablecoin; // e.g., USDC, USDT, DAI

    // ----- PROJECT MODEL -----
    struct Project {
        string name;
        string metadataURI;      // Off-chain details: docs, images, etc.
        address sponsor;         // Project sponsor/developer
        uint256 fundingGoal;     // Target amount in stablecoin smallest units
        uint256 minInvestment;   // Minimum per investor per contribution
        uint256 totalRaised;     // Total stablecoin raised
        uint256 deadline;        // Timestamp for funding end
        bool fundingClosed;
        bool goalReached;

        // Tokenization
        uint256 totalSupply;     // Total project tokens minted
        mapping(address => uint256) balances; // investor => project tokens
        mapping(address => bool) isInvestor;
        address[] investors;
    }

    uint256 public nextProjectId;
    mapping(uint256 => Project) private projects;

    // ----- EVENTS -----
    event ProjectCreated(
        uint256 indexed projectId,
        string name,
        address indexed sponsor,
        uint256 fundingGoal,
        uint256 deadline
    );

    event Invested(
        uint256 indexed projectId,
        address indexed investor,
        uint256 amountStable,
        uint256 projectTokensMinted
    );

    event FundingClosed(
        uint256 indexed projectId,
        bool goalReached,
        uint256 totalRaised
    );

    event CapitalWithdrawn(
        uint256 indexed projectId,
        address indexed sponsor,
        uint256 amount
    );

    event RefundClaimed(
        uint256 indexed projectId,
        address indexed investor,
        uint256 amount
    );

    event ReturnsDistributed(
        uint256 indexed projectId,
        uint256 totalAmount
    );

    constructor(address _stablecoin) {
        require(_stablecoin != address(0), "Stablecoin required");
        admin = msg.sender;
        stablecoin = IERC20(_stablecoin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlySponsor(uint256 projectId) {
        require(msg.sender == projects[projectId].sponsor, "Not sponsor");
        _;
    }

    // ----- PROJECT CREATION -----

    function createProject(
        string memory name,
        string memory metadataURI,
        uint256 fundingGoal,
        uint256 minInvestment,
        uint256 durationSeconds,
        address sponsor
    ) external onlyAdmin returns (uint256 projectId) {
        require(fundingGoal > 0, "Goal must be > 0");
        require(durationSeconds > 0, "Duration must be > 0");
        require(minInvestment > 0, "Min investment > 0");
        require(sponsor != address(0), "Sponsor required");

        projectId = nextProjectId;
        nextProjectId++;

        Project storage p = projects[projectId];
        p.name = name;
        p.metadataURI = metadataURI;
        p.sponsor = sponsor;
        p.fundingGoal = fundingGoal;
        p.minInvestment = minInvestment;
        p.deadline = block.timestamp + durationSeconds;

        emit ProjectCreated(projectId, name, sponsor, fundingGoal, p.deadline);
    }

    // ----- INVESTING -----

    /// @notice Investor approves this contract for "amount" stablecoin, then calls invest().
    function invest(uint256 projectId, uint256 amount) external {
        Project storage p = projects[projectId];
        require(!p.fundingClosed, "Funding closed");
        require(block.timestamp <= p.deadline, "Deadline passed");
        require(amount >= p.minInvestment, "Below min investment");

        // Pull stablecoin from investor
        require(
            stablecoin.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Simple 1:1 ratio: 1 unit stablecoin = 1 project token
        uint256 tokensToMint = amount;

        if (!p.isInvestor[msg.sender]) {
            p.isInvestor[msg.sender] = true;
            p.investors.push(msg.sender);
        }

        p.balances[msg.sender] += tokensToMint;
        p.totalSupply += tokensToMint;
        p.totalRaised += amount;

        emit Invested(projectId, msg.sender, amount, tokensToMint);
    }

    // ----- FUNDING STATE -----

    function closeFunding(uint256 projectId) external onlySponsor(projectId) {
        Project storage p = projects[projectId];
        require(!p.fundingClosed, "Already closed");
        require(
            block.timestamp > p.deadline || p.totalRaised >= p.fundingGoal,
            "Too early to close"
        );

        p.fundingClosed = true;
        p.goalReached = (p.totalRaised >= p.fundingGoal);

        emit FundingClosed(projectId, p.goalReached, p.totalRaised);
    }

    /// @notice Sponsor withdraws raised capital if goal reached.
    function withdrawCapital(uint256 projectId, uint256 amount)
        external
        onlySponsor(projectId)
    {
        Project storage p = projects[projectId];
        require(p.fundingClosed, "Funding not closed");
        require(p.goalReached, "Goal not reached");
        require(amount <= p.totalRaised, "Amount too high");

        p.totalRaised -= amount;
        require(stablecoin.transfer(p.sponsor, amount), "Transfer failed");

        emit CapitalWithdrawn(projectId, p.sponsor, amount);
    }

    // ----- REFUNDS -----

    /// @notice If project fails (goal not reached), investors can get stablecoin back.
    function claimRefund(uint256 projectId) external {
        Project storage p = projects[projectId];
        require(p.fundingClosed, "Funding not closed");
        require(!p.goalReached, "Goal reached; no refund");
        uint256 tokens = p.balances[msg.sender];
        require(tokens > 0, "Nothing to refund");

        // 1:1 mapping: tokens == invested stablecoin amount
        p.balances[msg.sender] = 0;

        require(stablecoin.transfer(msg.sender, tokens), "Refund failed");

        emit RefundClaimed(projectId, msg.sender, tokens);
    }

    // ----- RETURNS DISTRIBUTION -----

    /// @notice Sponsor deposits stablecoin profit to be distributed to token holders.
    /// @dev Sponsor must approve this contract to pull "amount" stablecoin before calling.
    function depositAndDistributeReturns(uint256 projectId, uint256 amount)
        external
        onlySponsor(projectId)
    {
        Project storage p = projects[projectId];
        require(p.fundingClosed, "Funding not closed");
        require(p.goalReached, "Goal not reached");
        require(amount > 0, "Zero amount");
        require(p.totalSupply > 0, "No tokens");

        // Pull from sponsor
        require(
            stablecoin.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 length = p.investors.length;
        for (uint256 i = 0; i < length; i++) {
            address investor = p.investors[i];
            uint256 balance = p.balances[investor];
            if (balance == 0) continue;

            uint256 share = (amount * balance) / p.totalSupply;
            if (share > 0) {
                require(stablecoin.transfer(investor, share), "Payout failed");
            }
        }

        emit ReturnsDistributed(projectId, amount);
    }

    // ----- VIEW HELPERS & "ERC20-LIKE" READS -----

    function getProjectInfo(uint256 projectId)
        external
        view
        returns (
            string memory name,
            string memory metadataURI,
            address sponsor,
            uint256 fundingGoal,
            uint256 minInvestment,
            uint256 totalRaised,
            uint256 deadline,
            bool fundingClosed,
            bool goalReached,
            uint256 totalSupply
        )
    {
        Project storage p = projects[projectId];
        return (
            p.name,
            p.metadataURI,
            p.sponsor,
            p.fundingGoal,
            p.minInvestment,
            p.totalRaised,
            p.deadline,
            p.fundingClosed,
            p.goalReached,
            p.totalSupply
        );
    }

    function getProjectInvestors(uint256 projectId)
        external
        view
        returns (address[] memory)
    {
        return projects[projectId].investors;
    }

    function balanceOf(uint256 projectId, address investor)
        external
        view
        returns (uint256)
    {
        return projects[projectId].balances[investor];
    }

    function investorShareWad(uint256 projectId, address investor)
        external
        view
        returns (uint256)
    {
        Project storage p = projects[projectId];
        if (p.totalSupply == 0) return 0;
        // scaled by 1e18 for convenience
        return (p.balances[investor] * 1e18) / p.totalSupply;
    }
}
