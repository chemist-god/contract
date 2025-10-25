// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title School Management System
/// @notice This contract manages students, teachers, courses, attendance, and grades
contract SchoolManagement {
    address public admin;

    enum Role {
        None,
        Student,
        Teacher
    }

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
    mapping(uint256 => Course) private courses;
    uint256 public courseCount;

    // Attendance: courseId => date => student => present
    mapping(uint256 => mapping(string => mapping(address => bool))) public attendance;

    // Grades: courseId => student => grade
    mapping(uint256 => mapping(address => string)) public grades;

    // ------------------------ EVENTS ------------------------
    event UserRegistered(address indexed user, string name, Role role);
    event CourseCreated(uint256 indexed courseId, string title, address indexed teacher, uint256 capacity);
    event StudentEnrolled(uint256 indexed courseId, address indexed student);
    event AttendanceMarked(uint256 indexed courseId, string date, address indexed student, bool present);
    event GradeRecorded(uint256 indexed courseId, address indexed student, string grade);

    // ------------------------ MODIFIERS ------------------------
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized: Admin only");
        _;
    }

    modifier onlyTeacher() {
        require(users[msg.sender].role == Role.Teacher, "Not authorized: Teacher only");
        _;
    }

    modifier onlyStudent() {
        require(users[msg.sender].role == Role.Student, "Not authorized: Student only");
        _;
    }

    modifier validCourse(uint256 courseId) {
        require(courseId > 0 && courseId <= courseCount, "Invalid course ID");
        _;
    }

    // ------------------------ CONSTRUCTOR ------------------------
    constructor() {
        admin = msg.sender;
    }

    // ------------------------ ADMIN FUNCTIONS ------------------------
    function registerUser(address userAddr, string calldata name, Role role) external onlyAdmin {
        require(!users[userAddr].registered, "User already registered");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(role == Role.Student || role == Role.Teacher, "Invalid role");

        users[userAddr] = User(name, role, true);
        emit UserRegistered(userAddr, name, role);
    }

    // ------------------------ TEACHER FUNCTIONS ------------------------
    function createCourse(string calldata title, uint256 capacity) external onlyTeacher {
        require(bytes(title).length > 0, "Course title cannot be empty");
        require(capacity > 0, "Capacity must be greater than zero");

        courseCount++;
        Course storage c = courses[courseCount];
        c.title = title;
        c.teacher = msg.sender;
        c.capacity = capacity;

        emit CourseCreated(courseCount, title, msg.sender, capacity);
    }

    function markAttendance(uint256 courseId, string calldata date, address student)
        external
        onlyTeacher
        validCourse(courseId)
    {
        Course storage c = courses[courseId];
        require(c.teacher == msg.sender, "Not your course");
        require(c.enrolledStudents[student], "Student not enrolled");

        attendance[courseId][date][student] = true;
        emit AttendanceMarked(courseId, date, student, true);
    }

    function recordGrade(uint256 courseId, address student, string calldata grade)
        external
        onlyTeacher
        validCourse(courseId)
    {
        Course storage c = courses[courseId];
        require(c.teacher == msg.sender, "Not your course");
        require(c.enrolledStudents[student], "Student not enrolled");
        require(bytes(grade).length > 0, "Grade cannot be empty");

        grades[courseId][student] = grade;
        emit GradeRecorded(courseId, student, grade);
    }

    // ------------------------ STUDENT FUNCTIONS ------------------------
    function enrollInCourse(uint256 courseId) external onlyStudent validCourse(courseId) {
        Course storage c = courses[courseId];
        require(c.enrolledCount < c.capacity, "Course is full");
        require(!c.enrolledStudents[msg.sender], "Already enrolled");

        c.enrolledStudents[msg.sender] = true;
        c.enrolledCount++;

        emit StudentEnrolled(courseId, msg.sender);
    }

    function getAttendance(uint256 courseId, string calldata date)
        external
        view
        onlyStudent
        validCourse(courseId)
        returns (bool)
    {
        return attendance[courseId][date][msg.sender];
    }

    function getTranscript()
        external
        view
        onlyStudent
        returns (string[] memory titles, string[] memory gradeList)
    {
        uint256 count;
        for (uint256 i = 1; i <= courseCount; i++) {
            if (courses[i].enrolledStudents[msg.sender]) {
                count++;
            }
        }

        titles = new string[](count);
        gradeList = new string[](count);

        uint256 index;
        for (uint256 i = 1; i <= courseCount; i++) {
            if (courses[i].enrolledStudents[msg.sender]) {
                titles[index] = courses[i].title;
                gradeList[index] = grades[i][msg.sender];
                index++;
            }
        }
    }

    // ------------------------ PUBLIC VIEW FUNCTIONS ------------------------
    function getCourse(uint256 courseId)
        external
        view
        validCourse(courseId)
        returns (string memory title, address teacher, uint256 capacity, uint256 enrolledCount)
    {
        Course storage c = courses[courseId];
        return (c.title, c.teacher, c.capacity, c.enrolledCount);
    }

    function isEnrolled(uint256 courseId, address student)
        external
        view
        validCourse(courseId)
        returns (bool)
    {
        return courses[courseId].enrolledStudents[student];
    }

    function getUser(address userAddr) external view returns (string memory name, Role role, bool registered) {
        User memory u = users[userAddr];
        return (u.name, u.role, u.registered);
    }
}
