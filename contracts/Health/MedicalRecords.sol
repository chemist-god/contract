// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Medical Record Access Control with DID Registry
contract MedicalRecordAccessControl {
    struct AccessGrant {
        address grantee;          // Provider wallet or DID address
        string recordPointer;     // IPFS CID or S3 key hash representing record
        uint256 validUntil;       // Expiry timestamp
        bool revoked;             // If true, access revoked early
    }

    // Maps patient address => record pointer => AccessGrant
    mapping(address => mapping(string => AccessGrant)) public grants;

    // Maps recordPointer to owner address
    mapping(string => address) public recordOwner;

    // DID registry mappings
    mapping(address => string) public didToAddress;
    mapping(string => address) public addressToDID;

    }
