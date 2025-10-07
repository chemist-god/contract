// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthRecordAccess {

    struct AccessGrant {
        address grantee;        // Provider wallet/DID
        string recordPointer;   // IPFS CID or S3 key hash
        uint256 validUntil;     // Expiry timestamp
        bool revoked;           // Can be revoked early
    }

    // Mapping: patient address => recordPointer => AccessGrant
    mapping(address => mapping(string => AccessGrant)) public grants;

    // Mapping: recordPointer => owner address
    mapping(string => address) public recordOwner;

    // Event emitted when access is granted
    event AccessGranted(address indexed patient, address indexed grantee, string recordPointer);

    // Grant access to a record for a specific duration
    function grantAccess(
        address _grantee,
        string calldata _recordPointer,
        uint256 _durationDays
    ) external {
        require(recordOwner[_recordPointer] == msg.sender, "Not the record owner");

        grants[msg.sender][_recordPointer] = AccessGrant({
            grantee: _grantee,
            recordPointer: _recordPointer,
            validUntil: block.timestamp + (_durationDays * 1 days),
            revoked: false
        });

        emit AccessGranted(msg.sender, _grantee, _recordPointer);
    }

    // Optional: Function to revoke access early
    
}
