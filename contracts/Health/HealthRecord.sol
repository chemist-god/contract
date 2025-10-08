// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract HealthRecordRegistry {

    struct HealthRecord {
        string ipfsCID;             // IPFS content identifier
        string encryptionMethod;    // e.g., "AES-256-GCM-ECDH"
        string keyAccessPointer;    // e.g., "/keys/{grantId}" or "request_via_app"
        uint256 createdAt;          // Timestamp of record creation
        bool active;                // Flag to indicate if record is active
    }

   
}
