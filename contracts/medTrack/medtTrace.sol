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
    
    // --- Helper Functions ---

    /**
     * @dev Converts a bytes32 value to its ASCII string representation.
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = _bytes32[j];
        }
        return string(bytesArray);
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

    // --- Admin Functions (for managing roles) ---
    function grantRole(address _account, string memory _role) public onlyAdmin {
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("manufacturer"))) {
            manufacturers[_account] = true;
            emit RoleGranted(_account, "manufacturer");
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("sterilizationUnit"))) {
            sterilizationUnits[_account] = true;
            emit RoleGranted(_account, "sterilizationUnit");
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("healthcareProfessional"))) {
            healthcareProfessionals[_account] = true;
            emit RoleGranted(_account, "healthcareProfessional");
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("disposalUnit"))) {
            disposalUnits[_account] = true;
            emit RoleGranted(_account, "disposalUnit");
        } else {
            revert("Invalid role");
        }
    }

    function revokeRole(address _account, string memory _role) public onlyAdmin {
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("manufacturer"))) {
            manufacturers[_account] = false;
            emit RoleRevoked(_account, "manufacturer");
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("sterilizationUnit"))) {
            sterilizationUnits[_account] = false;
            emit RoleRevoked(_account, "sterilizationUnit");
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("healthcareProfessional"))) {
            healthcareProfessionals[_account] = false;
            emit RoleRevoked(_account, "healthcareProfessional");
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("disposalUnit"))) {
            disposalUnits[_account] = false;
            emit RoleRevoked(_account, "disposalUnit");
        } else {
            revert("Invalid role");
        }
    }

    // --- Core Functions ---

    /**
     * @dev Registers a new medical tool.
     * @param _toolID Unique identifier for the tool.
     * @param _toolType Type of the tool (from enum).
     * @param _isReusable True if the tool can be reused after sterilization.
     */
    function registerTool(string memory _toolID, ToolType _toolType, bool _isReusable) public onlyManufacturer {
        require(bytes(medicalTools[_toolID].toolID).length == 0, "Tool ID already registered");

        medicalTools[_toolID] = MedicalTool({
            toolID: _toolID,
            toolType: _toolType,
            manufacturerDate: block.timestamp,
            isReusable: _isReusable,
            isSterile: _isReusable ? false : true, // Disposable tools are considered sterile on registration, reusable are not until sterilized
            isDisposed: false,
            lastSterilizationTime: 0,
            lastUsedBy: address(0),
            lastPatientHash: bytes32(0),
            usageCount: 0
        });

        toolHistory[_toolID].push(ToolEvent({
            toolID: _toolID,
            eventType: "Registration",
            timestamp: block.timestamp,
            performer: msg.sender,
            details: string(abi.encodePacked("Type: ", uintToString(uint256(_toolType)), ", Reusable: ", _isReusable ? "Yes" : "No"))
        }));

        emit ToolRegistered(_toolID, _toolType, _isReusable, msg.sender);
    }

    /**
     * @dev Logs a sterilization event for a reusable tool.
     * @param _toolID The ID of the tool being sterilized.
     * @param _method The sterilization method used.
     * @param _sterilizationResultHash A hash of the sterilization report/sensor data (future IoT integration).
     */
    function sterilizeTool(string memory _toolID, SterilizationMethod _method, bytes32 _sterilizationResultHash) public onlySterilizationUnit {
        MedicalTool storage tool = medicalTools[_toolID];
        require(bytes(tool.toolID).length > 0, "Tool not registered");
        require(tool.isReusable, "Only reusable tools can be sterilized");
        require(!tool.isDisposed, "Tool has already been disposed");

        tool.isSterile = true;
        tool.lastSterilizationTime = block.timestamp;
        tool.lastUsedBy = address(0); // Reset last user
        tool.lastPatientHash = bytes32(0); // Reset last patient
        tool.usageCount = 0; // Reset usage count after sterilization

        toolHistory[_toolID].push(ToolEvent({
            toolID: _toolID,
            eventType: "Sterilization",
            timestamp: block.timestamp,
            performer: msg.sender,
            details: string(abi.encodePacked("Method: ", uintToString(uint256(_method)), ", Result Hash: ", bytes32ToString(_sterilizationResultHash)))
        }));

        emit ToolSterilized(_toolID, _method, msg.sender, block.timestamp);
    }

    /**
     * @dev Logs the usage of a medical tool.
     * @param _toolID The ID of the tool being used.
     * @param _patientIDHash Hashed ID of the patient (for privacy).
     * @param _procedureType The type of medical procedure.
     */
    function useTool(string memory _toolID, bytes32 _patientIDHash, string memory _procedureType) public onlyHealthcareProfessional {
        MedicalTool storage tool = medicalTools[_toolID];
        require(bytes(tool.toolID).length > 0, "Tool not registered");
        require(!tool.isDisposed, "Tool has already been disposed");
        require(tool.isSterile, "Tool is not sterile and cannot be used");

        tool.isSterile = false; // A tool is no longer sterile after use
        tool.lastUsedBy = msg.sender;
        tool.lastPatientHash = _patientIDHash;
        tool.usageCount++;

        toolHistory[_toolID].push(ToolEvent({
            toolID: _toolID,
            eventType: "Usage",
            timestamp: block.timestamp,
            performer: msg.sender,
            details: string(abi.encodePacked("Patient Hash: ", bytes32ToString(_patientIDHash), ", Procedure: ", _procedureType))
        }));

        emit ToolUsed(_toolID, _patientIDHash, _procedureType, msg.sender, block.timestamp);
    }

    /**
     * @dev Logs the disposal of a medical tool.
     * @param _toolID The ID of the tool being disposed.
     */
    function disposeTool(string memory _toolID) public onlyDisposalUnit {
        MedicalTool storage tool = medicalTools[_toolID];
        require(bytes(tool.toolID).length > 0, "Tool not registered");
        require(!tool.isDisposed, "Tool already marked as disposed");

        tool.isDisposed = true;
        tool.isSterile = false; // Cannot be sterile if disposed

        toolHistory[_toolID].push(ToolEvent({
            toolID: _toolID,
            eventType: "Disposal",
            timestamp: block.timestamp,
            performer: msg.sender,
            details: "Tool permanently disposed."
        }));

        emit ToolDisposed(_toolID, msg.sender, block.timestamp);
    }

    // --- Query Functions ---

    /**
     * @dev Gets the current status of a medical tool.
     * @param _toolID The ID of the tool.
     * @return The MedicalTool struct.
     */
    function getToolStatus(string memory _toolID) public view returns (MedicalTool memory) {
        require(bytes(medicalTools[_toolID].toolID).length > 0, "Tool not registered");
        return medicalTools[_toolID];
    }

    /**
     * @dev Gets the entire history of a medical tool.
     * @param _toolID The ID of the tool.
     * @return An array of ToolEvent structs.
     */
    function getToolHistory(string memory _toolID) public view returns (ToolEvent[] memory) {
        require(bytes(medicalTools[_toolID].toolID).length > 0, "Tool not registered");
        return toolHistory[_toolID];
    }

    // --- Utility Functions (for string conversions in events/details) ---
    function uintToString(uint256 v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint256 x = v;
        uint256 s = 0;
        while (x > 0) {
            x /= 10;
            s++;
        }
        bytes memory b = new bytes(s);
        while (v > 0) {
            s--;
            b[s] = bytes1(uint8(48 + v % 10));
            v /= 10;
        }
        return string(b);
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory b = new bytes(64); // Each byte is two hex chars
        for (uint i = 0; i < 32; i++) {
            uint8 byteVal = uint8(_bytes32[i]);
            uint8 highNibble = (byteVal >> 4) & 0x0F;
            uint8 lowNibble = byteVal & 0x0F;
            b[i * 2] = _toAsciiChar(highNibble);
            b[i * 2 + 1] = _toAsciiChar(lowNibble);
        }
        return string(b);
    }

   function _toAsciiChar(uint8 nibble) internal pure returns (bytes1) {
        if (nibble < 10) {
            return bytes1(uint8(48 + nibble)); // '0' through '9'
        } else {
            return bytes1(uint8(97 + (nibble - 10))); // 'a' through 'f'
        }
    }
}