// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SmartAttendance {
    // --- Roles (bytes32) ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant ORG_ADMIN_ROLE     = keccak256("ORG_ADMIN_ROLE");
    bytes32 public constant ORGANIZER_ROLE     = keccak256("ORGANIZER_ROLE");
    bytes32 public constant VERIFIER_ROLE      = keccak256("VERIFIER_ROLE");
    bytes32 public constant AUDITOR_ROLE       = keccak256("AUDITOR_ROLE");

    address public deployer;

    // simple role storage: role => account => bool
    mapping(bytes32 => mapping(address => bool)) private _roles;

    
}
