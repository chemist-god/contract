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

    // --- Role management (simple) ---
    function grantRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    // --- Organization management ---
    function createOrg(address admin, bytes32 orgSalt) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        require(admin != address(0), "admin zero");
        uint256 id = _nextOrgId++;
        orgs[id] = Org({
            id: id,
            admin: admin,
            orgSalt: orgSalt,
            exists: true
        });
        // grant org admin role to the admin address
        _roles[ORG_ADMIN_ROLE][admin] = true;
        emit RoleGranted(ORG_ADMIN_ROLE, admin, msg.sender);

        emit OrgCreated(id, admin);
        return id;
    }

    function updateOrgSalt(uint256 orgId, bytes32 newSalt) external {
        require(orgs[orgId].exists, "org not exists");
        address adminAddr = orgs[orgId].admin;
        require(msg.sender == adminAddr || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not authorized");
        orgs[orgId].orgSalt = newSalt;
    }

    // --- Event management ---
    function createEvent(
        uint256 orgId,
        string calldata name,
        uint256 startTimestamp,
        uint256 endTimestamp,
        string calldata ipfsMetaCid
    ) external returns (uint256) {
        require(orgs[orgId].exists, "org not exists");
        // allow org admin, organizer, or default admin
        require(
            hasRole(ORG_ADMIN_ROLE, msg.sender) ||
            hasRole(ORGANIZER_ROLE, msg.sender) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "not authorized"
        );

        uint256 id = _nextEventId++;
        events[id] = EventStruct({
            id: id,
            orgId: orgId,
            name: name,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            ipfsMetaCid: ipfsMetaCid,
            creator: msg.sender,
            exists: true
        });

        emit EventCreated(id, orgId, name);
        return id;
    }

    // --- Verifier registry ---
    function registerVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(verifier != address(0), "verifier zero");
        _roles[VERIFIER_ROLE][verifier] = true;
        emit VerifierRegistered(verifier, msg.sender);
        emit RoleGranted(VERIFIER_ROLE, verifier, msg.sender);
    }

    function unregisterVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _roles[VERIFIER_ROLE][verifier] = false;
        emit VerifierUnregistered(verifier, msg.sender);
        emit RoleRevoked(VERIFIER_ROLE, verifier, msg.sender);
    }

    // --- EIP-712 typed data hashing helper ---
    function _hashAttendancePayload(
        uint256 orgId,
        uint256 eventId,
        bytes32 userHash,
        string memory ipfsCid,
        uint256 timestamp,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ATTENDANCE_TYPEHASH,
                orgId,
                eventId,
                userHash,
                keccak256(bytes(ipfsCid)),
                timestamp,
                nonce
            )
        );
    }

    // --- Signature recovery (EIP-191 style digest) ---
    function _toTypedDigest(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    // safe ecrecover handling (expects 65-byte signature)
    function _recoverSigner(bytes32 digest, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "invalid sig len");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // EIP-2 still allows v to be 27 or 28
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "invalid v");
        // solhint-disable-next-line arg-overflow
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "zero signer");
        return signer;
    }

    // --- Record attendance by signature (verifier signs) ---
    // Off-chain the verifier signs the typed payload:
    // AttendancePayload(orgId, eventId, userHash, ipfsCid, timestamp, nonce)
    // Caller supplies signature and contract verifies signer has VERIFIER_ROLE and nonce is correct.
    function recordAttendanceBySignature(
        uint256 orgId,
        uint256 eventId,
        bytes32 userHash,
        string calldata ipfsCid,
        uint256 timestamp,
        uint256 nonce,
        bytes calldata signature
    ) external returns (uint256) {
        require(orgs[orgId].exists, "org missing");
        require(events[eventId].exists, "event missing");
        // hash payload and domain
        bytes32 structHash = _hashAttendancePayload(orgId, eventId, userHash, ipfsCid, timestamp, nonce);
        bytes32 digest = _toTypedDigest(structHash);

        address signer = _recoverSigner(digest, signature);
        require(hasRole(VERIFIER_ROLE, signer), "invalid signer (not verifier)");

        // replay protection: require nonce == verifierNonce[signer] + 1
        require(nonce == verifierNonce[signer] + 1, "bad nonce");
        verifierNonce[signer] = nonce;

        // create attendance
        uint256 aid = _nextAttendanceId++;
        attendances[aid] = Attendance({
            id: aid,
            orgId: orgId,
            eventId: eventId,
            userHash: userHash,
            ipfsCid: ipfsCid,
            timestamp: timestamp,
            verifier: signer,
            status: AttendanceStatus.Confirmed
        });

        emit AttendanceRecorded(aid, eventId, userHash, signer);
        return aid;
    }

   
}
