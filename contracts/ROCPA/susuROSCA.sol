// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SusuROSCA is ReentrancyGuard {
    // State Variables
    address[] public members;
    uint public contributionAmount;
    uint public currentRound;
    uint public totalRounds;
    uint public roundDeadline;
    uint public constant roundDuration = 7 days;
    uint public constant gracePeriod = 1 days;
    address public admin;
    
    // Mappings
    mapping(address => bool) public isMember;
    mapping(address => bool) public hasReceived;
    mapping(uint => mapping(address => bool)) public roundContributions;
    mapping(address => uint) public contributions;
    mapping(address => uint) public lastContributionTime;
    mapping(address => bool) public emergencyVotes;
    mapping(address => bool) public extensionVotes;
    mapping(uint => address) public roundToRecipient;
    
    