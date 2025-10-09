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

    
}
