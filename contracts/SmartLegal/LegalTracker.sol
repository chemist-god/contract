// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title LegalDeadlineTracker
 * @dev Simple smart contract for tracking legal deadlines and renewals
 */
contract LegalDeadlineTracker {
    
    // --- Structs ---
    
    struct Matter {
        uint256 id;
        string matterNumber;
        string clientName;
        string lawyerName;
        uint256 createdAt;
        bool isActive;
    }
    
    struct Deadline {
        uint256 id;
        uint256 matterId;
        string description;
        uint256 deadlineDate;
        uint256 reminderDate;
        bool isCompleted;
        string deadlineType; // "filing", "hearing", "renewal", etc.
    }
    
    struct License {
        uint256 id;
        uint256 matterId;
        string licenseType;
        string licenseNumber;
        uint256 expiryDate;
        uint256 renewalDate;
        bool isActive;
    }
    
    // --- State Variables ---
    
    uint256 private matterCounter;
    uint256 private deadlineCounter;
    uint256 private licenseCounter;
    
   
}