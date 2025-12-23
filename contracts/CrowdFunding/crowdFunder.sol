// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Real Estate Crowdfunding Contract
/// @notice Single-project crowdfunding: investors deposit, sponsor can close funding and distribute returns.
contract RealEstateCrowdfund {
    address public sponsor;          // Project owner / admin
    string public projectName;       // Name or short description
    uint256 public fundingGoal;      // Target amount in wei
    uint256 public deadline;         // Timestamp when funding ends
    bool public fundingClosed;       // True when sponsor closes funding
    bool public goalReached;         // True if total >= fundingGoal

    uint256 public totalInvested;    // Total amount invested

    
}
