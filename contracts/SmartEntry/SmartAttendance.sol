// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SmartAttendance {
    // --- Roles (bytes32) ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant ORG_ADMIN_ROLE     = keccak256("ORG_ADMIN_ROLE");
    bytes32 public constant ORGANIZER_ROLE     = keccak256("ORGANIZER_ROLE");
    bytes32 public constant VERIFIER_ROLE      = keccak256("VERIFIER_ROLE");
    bytes32 public constant AUDITOR_ROLE       = keccak256("AUDITOR_ROLE");

    address public deployer;

    // simple role storage: role => account => bool
    mapping(bytes32 => mapping(address => bool)) private _roles;

    // --- Domain separator for EIP-712 ---
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant ATTENDANCE_TYPEHASH = keccak256(
        "AttendancePayload(uint256 orgId,uint256 eventId,bytes32 userHash,string ipfsCid,uint256 timestamp,uint256 nonce)"
    );

    // --- Counters (simple) ---
    uint256 private _nextOrgId = 1;
    uint256 private _nextEventId = 1;
    uint256 private _nextAttendanceId = 1;

    // --- Data structures ---
    struct Org {
        uint256 id;
        address admin;
        bytes32 orgSalt;
        bool exists;
    }

    struct EventStruct {
        uint256 id;
        uint256 orgId;
        string name;
        uint256 startTimestamp;
        uint256 endTimestamp;
        string ipfsMetaCid;
        address creator;
        bool exists;
    }

    enum AttendanceStatus { Pending, Confirmed, Disputed, Revoked }

    struct Attendance {
        uint256 id;
        uint256 orgId;
        uint256 eventId;
        bytes32 userHash;    // keccak256(orgSalt + userExternalId)
        string ipfsCid;      // CID for evidence (off-chain)
        uint256 timestamp;   // claimed check-in time
        address verifier;    // signer address (verifier device)
        AttendanceStatus status;
    }

    // storage
    mapping(uint256 => Org) public orgs;
    mapping(uint256 => EventStruct) public events;
    mapping(uint256 => Attendance) public attendances;

    // verifier => latest nonce (we require incoming nonce == stored + 1)
    mapping(address => uint256) public verifierNonce;

    // --- Events ---
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event OrgCreated(uint256 indexed orgId, address indexed admin);
    event EventCreated(uint256 indexed eventId, uint256 indexed orgId, string name);
    event VerifierRegistered(address indexed verifier, address indexed by);
    event VerifierUnregistered(address indexed verifier, address indexed by);
    event AttendanceRecorded(uint256 indexed attendanceId, uint256 indexed eventId, bytes32 userHash, address verifier);
    event AttendanceStatusChanged(uint256 indexed attendanceId, AttendanceStatus status, address changedBy);

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "SmartAttendance: missing role");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory version) {
        deployer = msg.sender;
        _roles[DEFAULT_ADMIN_ROLE][msg.sender] = true;
        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);

        // compute DOMAIN_SEPARATOR (EIP-712 like)
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

   
}
