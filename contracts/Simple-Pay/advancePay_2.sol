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

    
}
