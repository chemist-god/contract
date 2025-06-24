// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MedicalToolTracker {
    enum ToolStatus { Registered, InUse, Sterilized, Disposed }

    struct Tool {
        string toolType;
        string batchId;
        address hospital;
        uint256 registeredAt;
        ToolStatus status;
        address lastHandledBy;
    }

    address public admin;
    uint256 public toolCount;

    mapping(uint256 => Tool) public tools;
    mapping(address => bool) public approvedPersonnel;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyApproved() {
        require(approvedPersonnel[msg.sender], "Unauthorized access");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    
}
