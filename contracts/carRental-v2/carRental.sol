// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title CarRentalSystem
 * @dev A smart contract for managing car rentals on the blockchain.
 * Owners can add cars, and users can rent and return them.
 */
contract CarRentalSystem {

    // Struct to represent a single car
    struct Car {
        uint256 id;             // Unique ID for the car
        string make;            // Car manufacturer
        string model;           // Car model
        uint256 year;           // Manufacturing year
        uint256 rentalRate;     // Rental rate per unit time (e.g., per day) in Wei
        bool isAvailable;       // Availability status of the car
        address payable owner;  // Address of the car owner
        address renter;         // Current renter's address (address(0) if not rented)
        uint256 rentedUntil;    // Timestamp when the car is rented until (0 if not rented)
    }

    // Mapping to store cars by their unique ID
    mapping(uint256 => Car) public cars;
    // Counter for generating unique car IDs
    uint256 public carCount;

    // Events to log important actions
    event CarAdded(
        uint256 indexed carId,
        address indexed owner,
        string make,
        string model,
        uint256 rentalRate
    );
    event CarRented(
        uint256 indexed carId,
        address indexed renter,
        uint256 amountPaid,
        uint256 rentedUntil
    );
    event CarReturned(
        uint256 indexed carId,
        address indexed previousRenter,
        address indexed owner,
        uint256 returnTime
    );

    /**
     * @dev Modifier to restrict access to the car's owner.
     */
    modifier onlyOwner(uint256 _carId) {
        require(msg.sender == cars[_carId].owner, "Only the car owner can call this function.");
        _;
    }

    /**
     * @dev Modifier to ensure the car is currently available.
     */
    modifier onlyAvailable(uint256 _carId) {
        require(cars[_carId].isAvailable, "Car is not available for rent.");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the current renter of the car.
     */
    modifier onlyRenter(uint256 _carId) {
        require(msg.sender == cars[_carId].renter, "Only the current renter can call this function.");
        _;
    }

    /**
     * @dev Constructor is not needed for this basic contract.
     */
    constructor() {
        carCount = 0; // Initialize car count
    }

    /**
     * @dev Adds a new car to the rental system.
     * @param _make The make of the car.
     * @param _model The model of the car.
     * @param _year The manufacturing year of the car.
     * @param _rentalRate The daily rental rate of the car in Wei.
     */
    function addCar(
        string calldata _make,
        string calldata _model,
        uint256 _year,
        uint256 _rentalRate
    ) public {
        carCount++; // Increment car count for new ID
        cars[carCount] = Car(
            carCount,
            _make,
            _model,
            _year,
            _rentalRate,
            true, // Initially available
            payable(msg.sender), // The sender is the owner
            address(0),  // No renter initially
            0            // Not rented until initially
        );
        emit CarAdded(carCount, msg.sender, _make, _model, _rentalRate);
    }

    
}
