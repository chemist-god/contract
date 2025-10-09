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

    
}
