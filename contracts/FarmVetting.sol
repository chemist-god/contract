// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FarmerVetting {
    address public admin;

    struct Farmer {
        string name;
        string location;
        uint reputationScore;
        bool isVetted;
        bool isEligible;
    }

    mapping(address => Farmer) public farmers;
    address[] public farmerList;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
    }
}
