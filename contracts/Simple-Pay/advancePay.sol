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

    
}
