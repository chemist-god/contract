// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title AdvancedPay - payment orders + escrow + pull payments
contract AdvancedPay {
    enum PaymentStatus {
        Pending,        // Created but not yet fully funded
        Funded,         // Fully funded by payer
        Completed,      // Claimed by payee
        Refunded,       // Refunded back to payer
        Cancelled       // Cancelled before funding/completion
    }

    struct Payment {
        address payer;      // Who should pay
        address payee;      // Who should receive
        uint256 amount;     // Total amount expected (wei)
        uint256 deposited;  // How much has been deposited so far
        PaymentStatus status;
    }

    // Payment id => Payment info
    mapping(uint256 => Payment) public payments;
    uint256 public nextPaymentId;

    event PaymentCreated(
        uint256 indexed id,
        address indexed payer,
        address indexed payee,
        uint256 amount
    );

    event PaymentFunded(
        uint256 indexed id,
        address indexed payer,
        uint256 amount,
        uint256 totalDeposited
    );

    event PaymentCompleted(
        uint256 indexed id,
        address indexed payee,
        uint256 amount
    );

    event PaymentRefunded(
        uint256 indexed id,
        address indexed payer,
        uint256 amount
    );

    event PaymentCancelled(
        uint256 indexed id
    );

   
}
