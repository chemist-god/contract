// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WorkAndPayCarSystem
 * @dev A smart contract for managing 'Work and Pay' car agreements.
 * Owners can list cars, assign them to drivers, and drivers make installment payments.
 * The contract tracks payments and allows owners to reclaim defaulting cars.
 */
contract WorkAndPayCarSystem {

    // Struct to represent a car under a 'Work and Pay' agreement
    struct Car {
        uint256 id;                   // Unique ID for the car
        string make;                  // Car manufacturer
        string model;                 // Car model
        uint256 year;                 // Manufacturing year
        address payable owner;        // Original owner of the car (who initiated the W&P agreement)

        bool isAvailableForAssignment; // True if the car is listed but not yet assigned to a driver
        bool isUnderWorkAndPay;       // True if the car is currently assigned to a driver under W&P
        address currentDriver;        // Address of the driver currently in the W&P agreement (address(0) if not assigned)

        uint256 totalSalesPrice;      // Total amount driver needs to pay to 'buy' the car in Wei
        uint256 installmentAmount;    // Amount due per payment interval in Wei
        uint256 paymentFrequencyDays; // How often payments are due, in days (e.g., 7 for weekly, 30 for monthly)
        uint256 lastPaymentTime;      // Timestamp of the last successful installment payment for the current driver
        uint256 amountPaidByDriver;   // Total amount paid by the current driver for THIS agreement in Wei
        bool isPaidOff;               // True if the total sales price has been paid by the current driver
    }

    // Mapping to store cars by their unique ID
    mapping(uint256 => Car) public cars;
    // Counter for generating unique car IDs
    uint256 public carCount;

    // Events to log important actions and state changes
    event WorkAndPayCarAdded(
        uint256 indexed carId,
        address indexed owner,
        string make,
        string model,
        uint256 totalSalesPrice,
        uint256 installmentAmount,
        uint256 paymentFrequencyDays
    );
    event CarAssigned(
        uint256 indexed carId,
        address indexed owner,
        address indexed driver,
        uint256 assignmentTime
    );
    event InstallmentPaid(
        uint256 indexed carId,
        address indexed driver,
        uint256 amountPaidThisInstallment,
        uint256 totalAmountPaid
    );
    event CarReclaimed(
        uint256 indexed carId,
        address indexed owner,
        address indexed previousDriver,
        uint256 reclaimTime
    );
    event CarPaidOff(
        uint256 indexed carId,
        address indexed driver,
        address indexed originalOwner,
        uint256 finalPaymentTime
    );

    /**
     * @dev Modifier to restrict access to the car's original owner.
     */
    modifier onlyOwner(uint256 _carId) {
        require(msg.sender == cars[_carId].owner, "Only the car owner can call this function.");
        _;
    }

    /**
     * @dev Modifier to ensure the car is currently available for assignment.
     */
    modifier onlyAvailableForAssignment(uint256 _carId) {
        require(cars[_carId].isAvailableForAssignment, "Car is not available for assignment.");
        _;
    }

    /**
     * @dev Modifier to ensure the car is currently under a Work and Pay agreement.
     */
    modifier onlyIfUnderWorkAndPay(uint256 _carId) {
        require(cars[_carId].isUnderWorkAndPay, "Car is not currently under a Work and Pay agreement.");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the current assigned driver of the car.
     */
    modifier onlyAssignedDriver(uint256 _carId) {
        require(msg.sender == cars[_carId].currentDriver, "Only the assigned driver can call this function.");
        _;
    }

    constructor() {
        carCount = 0; // Initialize car count
    }

}
