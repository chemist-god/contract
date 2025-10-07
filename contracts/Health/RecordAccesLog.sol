// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract RecordAccessLogger {

    // Modifier to restrict access to authorized entities
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Not authorized");
        _;
    }

    // Event emitted whenever a record access is attempted
    event RecordAccessAttempted(
        address indexed patient,
        address indexed requester,
        string recordPointer,
        bool allowed,
        uint256 timestamp
    );

    // Log an access attempt to a patient's record
    function logAccess(
        address _patient,
        address _requester,
        string calldata _recordPointer,
        bool _allowed
    ) external onlyAuthorized {
        emit RecordAccessAttempted(
            _patient,
            _requester,
            _recordPointer,
            _allowed,
            block.timestamp
        );
    }

    
}
