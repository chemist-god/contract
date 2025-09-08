// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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

    event FarmerRegistered(address indexed farmer, string name, string location);
    event FarmerVetted(address indexed farmer, uint score, bool isEligible);
    event ReputationAdjusted(address indexed farmer, int change, uint newScore);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    }
