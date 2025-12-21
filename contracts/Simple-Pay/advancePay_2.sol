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

    // --- Role management ---

    function addMerchant(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        isMerchant[account] = true;
        emit MerchantAdded(account);
    }

    function removeMerchant(address account) external onlyOwner {
        isMerchant[account] = false;
        emit MerchantRemoved(account);
    }

    function setRelayer(address relayer, bool allowed) external onlyOwner {
        isRelayer[relayer] = allowed;
        emit RelayerSet(relayer, allowed);
    }

    // --- Plan lifecycle ---

    function createPlan(
        IERC20 token,
        uint256 amount,
        uint256 interval
    ) external onlyMerchant returns (uint256 planId) {
        require(address(token) != address(0), "Token zero");
        require(amount > 0, "Amount = 0");
        require(interval >= 60, "Interval too small");

        planId = nextPlanId++;
        plans[planId] = Plan({
            merchant: msg.sender,
            token: token,
            amount: amount,
            interval: interval,
            active: true
        });

        emit PlanCreated(planId, msg.sender, address(token), amount, interval);
    }

    function setPlanActive(uint256 planId, bool active) external {
        Plan storage p = plans[planId];
        require(p.merchant != address(0), "Plan not found");
        require(msg.sender == p.merchant || msg.sender == owner, "Not authorized");
        p.active = active;
        emit PlanStatusChanged(planId, active);
    }

    // --- Subscribe / unsubscribe ---

    /// @notice Subscriber approves token to this contract before calling.
    function subscribe(uint256 planId) external returns (uint256 subId) {
        Plan storage p = plans[planId];
        require(p.merchant != address(0), "Plan not found");
        require(p.active, "Plan inactive");

        // take first payment immediately
        require(
            p.token.transferFrom(msg.sender, p.merchant, p.amount),
            "First payment failed"
        );

        subId = nextSubId++;
        subs[subId] = Subscription({
            planId: planId,
            subscriber: msg.sender,
            nextPaymentTime: block.timestamp + p.interval,
            active: true
        });

        emit Subscribed(subId, planId, msg.sender, block.timestamp);
        emit PaymentExecuted(subId, planId, msg.sender, p.amount, block.timestamp);
    }

    function unsubscribe(uint256 subId) external {
        Subscription storage s = subs[subId];
        require(s.active, "Not active");
        require(msg.sender == s.subscriber, "Not subscriber");
        s.active = false;
        emit Unsubscribed(subId);
    }

    // --- Recurring payment execution (anyone can call) ---

    function executePayment(uint256 subId) public {
        Subscription storage s = subs[subId];
        require(s.active, "Sub inactive");

        Plan storage p = plans[s.planId];
        require(p.active, "Plan inactive");
        require(block.timestamp >= s.nextPaymentTime, "Too early");

        s.nextPaymentTime = block.timestamp + p.interval;

        require(
            p.token.transferFrom(s.subscriber, p.merchant, p.amount),
            "Payment failed"
        );

        emit PaymentExecuted(subId, s.planId, s.subscriber, p.amount, block.timestamp);
    }

    // --- Meta-transaction style payment execution ---
    // Very simplified: subscriber signs off-chain, relayer calls this and pays gas.

    function executePaymentWithSig(
        uint256 subId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyRelayer {
        require(block.timestamp <= deadline, "Signature expired");

        Subscription storage sub = subs[subId];
        require(sub.active, "Sub inactive");

        uint256 nonce = nonces[sub.subscriber];

        // EIP-191 style prefixed hash (for demo purposes; for production use EIP-712)[web:59][web:62][web:68]
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                address(this),
                "EXECUTE_PAYMENT",
                subId,
                nonce,
                deadline
            )
        );
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );

        address signer = ecrecover(ethSignedHash, v, r, s);
        require(signer == sub.subscriber, "Invalid signer");

        nonces[sub.subscriber] = nonce + 1;

        // Now perform the regular payment logic
        executePayment(subId);
    }
}
