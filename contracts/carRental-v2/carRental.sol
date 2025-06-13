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

    /**
     * @dev Rents a car for a specified duration.
     * @param _carId The ID of the car to rent.
     * @param _rentalDuration The duration for which the car is rented, in days.
     * @return true if the car was successfully rented.
     */
    function rentCar(uint256 _carId, uint256 _rentalDuration)
        public
        payable
        onlyAvailable(_carId)
        returns (bool)
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        require(_rentalDuration > 0, "Rental duration must be greater than zero.");

        Car storage car = cars[_carId]; // Get a reference to the car

        // Calculate total rental amount
        uint256 totalRentalAmount = car.rentalRate * _rentalDuration;
        require(msg.value >= totalRentalAmount, "Insufficient payment for rental.");

        // Transfer rental amount to the car owner
        // Using `transfer` for security against reentrancy (though `call` is more flexible)
        // For simplicity and to demonstrate basic transfer, `transfer` is used here.
        // In a more complex system, consider pull payments or a separate payment processing logic.
        (bool success, ) = car.owner.call{value: totalRentalAmount}("");
        require(success, "Failed to transfer funds to owner.");

        // Update car status
        car.isAvailable = false;
        car.renter = msg.sender;
        car.rentedUntil = block.timestamp + (_rentalDuration * 1 days); // Calculate rented until timestamp

        // If overpaid, refund the difference
        if (msg.value > totalRentalAmount) {
            payable(msg.sender).transfer(msg.value - totalRentalAmount);
        }

        emit CarRented(_carId, msg.sender, totalRentalAmount, car.rentedUntil);
        return true;
    }

    /**
     * @dev Allows the current renter to return a car.
     * @param _carId The ID of the car to return.
     * @return true if the car was successfully returned.
     */
    function returnCar(uint256 _carId)
        public
        onlyRenter(_carId)
        returns (bool)
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");

        Car storage car = cars[_carId]; // Get a reference to the car

        // Check if the rental period has ended. If it hasn't, the owner keeps the full rental.
        // This is a simple implementation. A more advanced system might handle partial refunds.
        // For this contract, we simply set the car as available again.

        // Reset car status
        car.isAvailable = true;
        car.renter = address(0); // No current renter
        car.rentedUntil = 0;     // Reset rented until timestamp

        emit CarReturned(_carId, msg.sender, car.owner, block.timestamp);
        return true;
    }

    
}
