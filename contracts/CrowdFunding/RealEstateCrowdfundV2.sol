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

   
}
