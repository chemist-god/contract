// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MedTrace {

    // Enum for different tool types (can be expanded)
    enum ToolType { SurgicalScalpel, Forceps, Endoscope, BloodCollectionNeedle }

    // Enum for sterilization methods (can be expanded based on Ghana's practices)
    enum SterilizationMethod { Autoclave, GammaIrradiation, EthyleneOxide }

    // Struct to represent a medical tool
    struct MedicalTool {
        string toolID;              // Unique identifier for the tool (e.g., UDI, serial number)
        ToolType toolType;          // Type of the tool
        uint256 manufacturerDate;   // Timestamp of manufacturing
        bool isReusable;            // True if the tool is reusable
        bool isSterile;             // Current sterilization status
        bool isDisposed;            // True if the tool has been disposed
        uint256 lastSterilizationTime; // Timestamp of the last successful sterilization
        address lastUsedBy;         // Address of the last healthcare professional who used it
        bytes32 lastPatientHash;    // Hashed ID of the last patient it was used on (for privacy)
        uint256 usageCount;         // Number of times the tool has been used since last sterilization
    }

}