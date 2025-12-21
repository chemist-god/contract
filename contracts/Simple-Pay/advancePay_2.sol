// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @notice Minimal ERC20 interface
interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/// @title SubPay - ERC20 subscriptions with roles + meta-exec
contract SubPay {
    // --- Roles ---
    address public owner;
    mapping(address => bool) public isMerchant;
    mapping(address => bool) public isRelayer; // allowed to submit meta-txs

    // --- Subscription plan ---
    struct Plan {
        address merchant;
        IERC20 token;
        uint256 amount;      // per period (token units)
        uint256 interval;    // seconds between payments
        bool active;
    }

    // --- User subscription ---
    struct Subscription {
        uint256 planId;
        address subscriber;
        uint256 nextPaymentTime;
        bool active;
    }

    uint256 public nextPlanId;
    uint256 public nextSubId;

    mapping(uint256 => Plan) public plans;
    mapping(uint256 => Subscription) public subs;

    // replay protection for meta-txs: subscriber => nonce
    mapping(address => uint256) public nonces;

    // --- Events ---
    event MerchantAdded(address indexed merchant);
    event MerchantRemoved(address indexed merchant);
    event PlanCreated(uint256 indexed planId, address indexed merchant, address token, uint256 amount, uint256 interval);
    event PlanStatusChanged(uint256 indexed planId, bool active);
    event Subscribed(uint256 indexed subId, uint256 indexed planId, address indexed subscriber, uint256 firstPaymentTime);
    event Unsubscribed(uint256 indexed subId);
    event PaymentExecuted(uint256 indexed subId, uint256 indexed planId, address indexed subscriber, uint256 amount, uint256 paidAt);
    event RelayerSet(address indexed relayer, bool allowed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyMerchant() {
        require(isMerchant[msg.sender], "Not merchant");
        _;
    }

    modifier onlyRelayer() {
        require(isRelayer[msg.sender], "Not relayer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    
}
