// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public amount;
    bool public fundsReleased;

    constructor(address _beneficiary, address _arbiter) payable {
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        amount = msg.value;
        fundsReleased = false;
    }

    function releaseFunds() external {
        require(msg.sender == arbiter, "Only arbiter can release funds");
        require(!fundsReleased, "Funds already released");

        fundsReleased = true;
        payable(beneficiary).transfer(amount);
    }
}
