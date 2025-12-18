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

    
}
