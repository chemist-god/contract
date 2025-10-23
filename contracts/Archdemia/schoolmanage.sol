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

    // Attendance: courseId => date => student => present
    mapping(uint256 => mapping(string => mapping(address => bool))) public attendance;

    // Grades: courseId => student => grade
    mapping(uint256 => mapping(address => string)) public grades;

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

    function registerUser(address userAddr, string memory name, Role role) public onlyAdmin {
        require(!users[userAddr].registered, "Already registered");
        users[userAddr] = User(name, role, true);
    }

    function createCourse(string memory title, uint256 capacity) public onlyTeacher {
        courseCount++;
        Course storage c = courses[courseCount];
        c.title = title;
        c.teacher = msg.sender;
        c.capacity = capacity;
        c.enrolledCount = 0;
    }

    function enrollInCourse(uint256 courseId) public onlyStudent {
        Course storage c = courses[courseId];
        require(c.enrolledCount < c.capacity, "Course full");
        require(!c.enrolledStudents[msg.sender], "Already enrolled");

        c.enrolledStudents[msg.sender] = true;
        c.enrolledCount++;
    }

    function markAttendance(uint256 courseId, string memory date, address student) public onlyTeacher {
        Course storage c = courses[courseId];
        require(c.teacher == msg.sender, "Not your course");
        require(c.enrolledStudents[student], "Student not enrolled");

        attendance[courseId][date][student] = true;
    }

    function getAttendance(uint256 courseId, string memory date) public view onlyStudent returns (bool) {
        return attendance[courseId][date][msg.sender];
    }

    function recordGrade(uint256 courseId, address student, string memory grade) public onlyTeacher {
        Course storage c = courses[courseId];
        require(c.teacher == msg.sender, "Not your course");
        require(c.enrolledStudents[student], "Student not enrolled");

        grades[courseId][student] = grade;
    }

    

    function getCourse(uint256 courseId) public view returns (string memory, address, uint256, uint256) {
        Course storage c = courses[courseId];
        return (c.title, c.teacher, c.capacity, c.enrolledCount);
    }
}
