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

    // Events
    event AccessGranted(address indexed owner, address indexed grantee, string recordPointer);
    event RecordAccessAttempted(
        address indexed patient,
        address indexed requester,
        string recordPointer,
        bool allowed,
        uint256 timestamp
    );

    // Contract deployer as authorized admin
    address public contractOwner;

    modifier onlyRecordOwner(string calldata _recordPointer) {
        require(msg.sender == recordOwner[_recordPointer], "Not record owner");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == contractOwner, "Not authorized");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    /// @notice Register ownership of a record pointer
    function registerRecord(string calldata _recordPointer) external {
        require(recordOwner[_recordPointer] == address(0), "Record already registered");
        recordOwner[_recordPointer] = msg.sender;
    }

    /// @notice Grant access to a record for a duration in days
    function grantAccess(
        address _grantee,
        string calldata _recordPointer,
        uint256 _durationDays
    ) external onlyRecordOwner(_recordPointer) {
        grants[msg.sender][_recordPointer] = AccessGrant({
            grantee: _grantee,
            recordPointer: _recordPointer,
            validUntil: block.timestamp + (_durationDays * 1 days),
            revoked: false
        });
        emit AccessGranted(msg.sender, _grantee, _recordPointer);
    }

    /// @notice Log access attempts (caller must be authorized)
    function logAccess(
        address _patient,
        address _requester,
        string calldata _recordPointer,
        bool _allowed
    ) external onlyAuthorized {
        emit RecordAccessAttempted(_patient, _requester, _recordPointer, _allowed, block.timestamp);
    }

    /// @notice Register a DID string for an address (one-time only)
    function registerDID(address _addr, string calldata _did) external {
        require(bytes(didToAddress[_addr]).length == 0, "DID already set");
        require(addressToDID[_did] == address(0), "Address already set");
        didToAddress[_addr] = _did;
        addressToDID[_did] = _addr;
    }

    /// @notice Check if a requester currently has valid, not-revoked access to a record
    function hasValidAccess(
        address _patient,
        string calldata _recordPointer,
        address _requester
    ) external view returns (bool) {
        AccessGrant memory grant = grants[_patient][_recordPointer];
        return
            grant.grantee == _requester &&
            !grant.revoked &&
            block.timestamp <= grant.validUntil;
    }

    /// @notice Allows record owner to revoke access before expiration
    function revokeAccess(string calldata _recordPointer) external onlyRecordOwner(_recordPointer) {
        AccessGrant storage grant = grants[msg.sender][_recordPointer];
        require(!grant.revoked, "Access already revoked");
        grant.revoked = true;
    }
}
