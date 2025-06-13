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

   
}
