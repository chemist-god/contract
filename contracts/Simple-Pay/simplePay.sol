// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title SimplePay - basic send & receive Ether
contract SimplePay {
    // Tracks how much Ether each address has deposited
    mapping(address => uint256) public balances;

    // Emitted when someone deposits Ether
    event Deposit(address indexed from, uint256 amount);

    // Emitted when someone withdraws Ether to their own address
    event Withdraw(address indexed to, uint256 amount);

    // Emitted when someone sends Ether to another user via the contract
    event Payment(address indexed from, address indexed to, uint256 amount);

    /// @notice Deposit Ether into your balance
    /// @dev msg.value is the amount of wei sent with the call
    function deposit() external payable {
        require(msg.value > 0, "No Ether sent");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw Ether from your balance to your own address
    /// @param amount Amount of wei to withdraw
    function withdraw(uint256 amount) external {
        require(amount > 0, "Zero amount");
        uint256 bal = balances[msg.sender];
        require(bal >= amount, "Insufficient balance");

        // effects
        balances[msg.sender] = bal - amount;

        // interaction
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Withdraw failed");

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Send Ether from your balance to another address
    /// @param to Recipient address
    /// @param amount Amount of wei to send
    function pay(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Zero amount");

        uint256 bal = balances[msg.sender];
        require(bal >= amount, "Insufficient balance");

        // effects
        balances[msg.sender] = bal - amount;
        balances[to] += amount;

        emit Payment(msg.sender, to, amount);
    }

    
}
