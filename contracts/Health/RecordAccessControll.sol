// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract RecordAccessControl {

    // -------------------- Structs --------------------

    struct AccessGrant {
        address grantee;         // Provider wallet or DID
        string recordPointer;    // IPFS CID or S3 key hash
        uint256 validUntil;      // Expiry timestamp
        bool revoked;            // Can be revoked early
    }

    // -------------------- State Variables --------------------

    // Mapping: patient address => recordPointer => AccessGrant
    mapping(address => mapping(string => AccessGrant)) public grants;

    // Mapping: recordPointer => owner address
    mapping(string => address) public recordOwner;

    // DID registry: address ↔ DID
    mapping(address => string) public didToAddress;
    mapping(string => address) public addressToDID;

    // -------------------- Events --------------------

    event AccessGranted(
        address indexed patient,
        address indexed grantee,
        string recordPointer
    );

    event RecordAccessAttempted(
        address indexed patient,
        address indexed requester,
        string recordPointer,
        bool allowed,
        uint256 timestamp
    );

    event DIDRegistered(
        address indexed user,
        string did
    );

    // -------------------- Modifiers --------------------

    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Not authorized");
        _;
    }

    // -------------------- Core Functions --------------------

    /// @notice Grants access to a record for a specific duration
    function grantAccess(
        address _grantee,
        string calldata _recordPointer,
        uint256 _durationDays
    ) external {
        require(msg.sender == recordOwner[_recordPointer], "Not owner");

        grants[msg.sender][_recordPointer] = AccessGrant({
            grantee: _grantee,
            recordPointer: _recordPointer,
            validUntil: block.timestamp + (_durationDays * 1 days),
            revoked: false
        });

        emit AccessGranted(msg.sender, _grantee, _recordPointer);
    }

    /// @notice Logs an access attempt to a record
    function logAccess(
        address _patient,
        address _requester,
        string calldata _recordPointer,
        bool _allowed
    ) external onlyAuthorized {
        emit RecordAccessAttempted(
            _patient,
            _requester,
            _recordPointer,
            _allowed,
            block.timestamp
        );
    }

    
}
