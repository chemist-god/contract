// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract HealthcareBooking {
    enum Status { Pending, Approved, Skipped, Unavailable, Completed }

    struct Patient {
        string name;
        uint256 severityScore;
        uint256 priorityRank;
        string contactMethod;
        Status status;
        uint256 appointmentDate;
    }

    address public admin;
    uint256 public bookingWindow; // e.g., Wednesdays
    uint256 public checkInWindow; // e.g., Thursdays

    mapping(uint256 => Patient[]) public appointmentsByDate;
    mapping(address => Patient) public patientRecords;

    event AppointmentBooked(address indexed patient, uint256 date);
    event StatusUpdated(address indexed patient, Status newStatus);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(uint256 _bookingWindow, uint256 _checkInWindow) {
        admin = msg.sender;
        bookingWindow = _bookingWindow;
        checkInWindow = _checkInWindow;
    }

    
}
