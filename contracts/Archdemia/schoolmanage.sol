// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SchoolManagement {
    address public admin;

    enum Role { None, Student, Teacher }

    struct User {
        string name;
        Role role;
        bool registered;
    }

    struct Course {
        string title;
        address teacher;
        uint256 capacity;
        uint256 enrolledCount;
        mapping(address => bool) enrolledStudents;
    }

    mapping(address => User) public users;
    mapping(uint256 => Course) public courses;
    uint256 public courseCount;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    modifier onlyTeacher() {
        require(users[msg.sender].role == Role.Teacher, "Only teachers allowed");
        _;
    }

    modifier onlyStudent() {
        require(users[msg.sender].role == Role.Student, "Only students allowed");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    
}
