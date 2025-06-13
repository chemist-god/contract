// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract CarRental {
    struct Car {
        uint id;
        string model;
        uint securityDeposit;
        uint rentalPrice;
        bool isAvailable;
        address payable owner;
    }

    struct Rental {
        uint carId;
        address renter;
        uint startTime;
        uint endTime;
        bool isActive;
    }

    uint public carCount;
    mapping(uint => Car) public cars;
    mapping(address => Rental) public rentals;
    mapping(address => uint) public deposits; // To store security deposits

    event CarRegistered(uint carId, string model, uint rentalPrice, uint securityDeposit, address owner);
    event CarRented(uint carId, address renter, uint startTime, uint endTime);
    event CarReturned(uint carId, address renter, uint refundAmount);

    function registerCar(string memory _model, uint _rentalPrice, uint _securityDeposit) public {
        carCount++;
        cars[carCount] = Car(carCount, _model, _securityDeposit, _rentalPrice, true, payable(msg.sender));
        emit CarRegistered(carCount, _model, _rentalPrice, _securityDeposit, msg.sender);
    }

    function rentCar(uint _carId, uint _duration) public payable {
        Car storage car = cars[_carId];
        require(car.isAvailable, "Car not available");
        uint totalRentalCost = car.rentalPrice * _duration;
        require(msg.value >= totalRentalCost + car.securityDeposit, "Insufficient payment for rental and security deposit");

        car.isAvailable = false;
        // Store the security deposit
        deposits[msg.sender] = car.securityDeposit;

        rentals[msg.sender] = Rental(_carId, msg.sender, block.timestamp, block.timestamp + _duration, true);
        
        // Transfer only the rental cost to the owner, contract holds the deposit
        car.owner.transfer(totalRentalCost);
        
        emit CarRented(_carId, msg.sender, block.timestamp, block.timestamp + _duration);
    }

    function returnCar(uint _carId) public {
        // Ensure the caller has an active rental for this car
        require(rentals[msg.sender].carId == _carId && rentals[msg.sender].isActive, "No active rental found for this car by the user.");

        Rental storage rental = rentals[msg.sender];
        require(rental.carId == _carId, "Not rented by user");
        require(rental.isActive, "Rental already ended");

        cars[_carId].isAvailable = true;
        rental.isActive = false;

        uint refundAmount = deposits[msg.sender];

        // Check for late return and apply a simple late fee (e.g., 10% of rental price per time unit of delay)
        if (block.timestamp > rental.endTime) {
            uint lateDuration = block.timestamp - rental.endTime;
            // Assuming rentalPrice is per unit of _duration used in rentCar
            // For simplicity, let's say late fee is 10% of car's rentalPrice per unit of time overdue.
            uint lateFee = (cars[_carId].rentalPrice / 10) * lateDuration; // Adjust fee logic as needed
            if (refundAmount >= lateFee) {
                refundAmount -= lateFee;
            } else {
                refundAmount = 0; // Late fee exceeds deposit
            }
        }

        deposits[msg.sender] = 0; // Clear the deposit for the user
        payable(msg.sender).transfer(refundAmount);
        emit CarReturned(_carId, msg.sender, refundAmount);
    }
}
