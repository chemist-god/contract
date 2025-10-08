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

    // Mapping: patient address => array of health records
    mapping(address => HealthRecord[]) public records;

    // Event emitted when a new health record is added
    event HealthRecordAdded(address indexed patient, string ipfsCID, uint256 timestamp);

    // Add a new health record for the sender
    function addHealthRecord(
        string calldata _ipfsCID,
        string calldata _encryptionMethod,
        string calldata _keyAccessPointer
    ) external {
        HealthRecord memory newRecord = HealthRecord({
            ipfsCID: _ipfsCID,
            encryptionMethod: _encryptionMethod,
            keyAccessPointer: _keyAccessPointer,
            createdAt: block.timestamp,
            active: true
        });

        records[msg.sender].push(newRecord);
        emit HealthRecordAdded(msg.sender, _ipfsCID, block.timestamp);
    }

    // Optional: Deactivate a record (e.g., if outdated or revoked)
    function deactivateRecord(uint256 index) external {
        require(index < records[msg.sender].length, "Invalid index");
        records[msg.sender][index].active = false;
    }

    
}
