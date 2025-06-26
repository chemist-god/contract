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

    // Struct to log an event in the tool's history
    struct ToolEvent {
        string toolID;
        string eventType;           // "Sterilization", "Usage", "Disposal", "Registration"
        uint256 timestamp;
        address performer;          // Address of the entity performing the action
        string details;             // Additional relevant details (e.g., sterilization method, procedure, patient hash)
    }

    // Mappings for storing data
    mapping(string => MedicalTool) public medicalTools; // toolID => MedicalTool details
    mapping(string => ToolEvent[]) public toolHistory;  // toolID => Array of events

    // Role-based access control
    mapping(address => bool) public manufacturers;
    mapping(address => bool) public sterilizationUnits;
    mapping(address => bool) public healthcareProfessionals;
    mapping(address => bool) public disposalUnits;
    address public admin; // Single admin for this PoC, can be multi-sig in production

    // Events to log important actions on the blockchain
    event ToolRegistered(string indexed toolID, ToolType toolType, bool isReusable, address manufacturer);
    event ToolSterilized(string indexed toolID, SterilizationMethod method, address unit, uint256 timestamp);
    event ToolUsed(string indexed toolID, bytes32 indexed patientHash, string procedure, address professional, uint256 timestamp);
    event ToolDisposed(string indexed toolID, address unit, uint256 timestamp);
    event RoleGranted(address indexed account, string role);
    event RoleRevoked(address indexed account, string role);


    // --- Constructor ---
    constructor() {
        admin = msg.sender; // Deployer is the initial admin
        manufacturers[msg.sender] = true; // For testing, deployer is also a manufacturer initially
        sterilizationUnits[msg.sender] = true; // For testing, deployer is also a sterilization unit
        healthcareProfessionals[msg.sender] = true; // For testing, deployer is also a healthcare professional
        disposalUnits[msg.sender] = true; // For testing, deployer is also a disposal unit
    }

    // --- Modifiers for Access Control ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyManufacturer() {
        require(manufacturers[msg.sender], "Only manufacturers can register tools");
        _;
    }

    modifier onlySterilizationUnit() {
        require(sterilizationUnits[msg.sender], "Only sterilization units can sterilize tools");
        _;
    }

    modifier onlyHealthcareProfessional() {
        require(healthcareProfessionals[msg.sender], "Only healthcare professionals can use tools");
        _;
    }

    modifier onlyDisposalUnit() {
        require(disposalUnits[msg.sender], "Only disposal units can dispose tools");
        _;
    }

  
}