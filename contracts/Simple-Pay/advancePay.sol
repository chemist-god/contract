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

    /// @notice Create a payment order between payer and payee
    /// @dev Can be created by anyone (often the payer or payee)
    function createPayment(
        address payer,
        address payee,
        uint256 amount
    ) external returns (uint256 id) {
        require(payer != address(0), "Invalid payer");
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be > 0");
        require(payer != payee, "Payer = payee");

        id = nextPaymentId++;
        payments[id] = Payment({
            payer: payer,
            payee: payee,
            amount: amount,
            deposited: 0,
            status: PaymentStatus.Pending
        });

        emit PaymentCreated(id, payer, payee, amount);
    }

    /// @notice Fund a payment order by sending Ether
    /// @dev Only the designated payer can fund this payment
    function fundPayment(uint256 id) external payable {
        Payment storage p = payments[id];
        require(p.amount > 0, "Payment does not exist");
        require(
            p.status == PaymentStatus.Pending || p.status == PaymentStatus.Funded,
            "Not fundable"
        );
        require(msg.sender == p.payer, "Only payer");
        require(msg.value > 0, "No Ether sent");
        require(p.deposited + msg.value <= p.amount, "Too much Ether");

        p.deposited += msg.value;

        if (p.deposited == p.amount) {
            p.status = PaymentStatus.Funded;
        }

        emit PaymentFunded(id, msg.sender, msg.value, p.deposited);
    }

    
}
