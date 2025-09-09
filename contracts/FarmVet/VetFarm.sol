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

    function registerFarmer(string memory _name, string memory _location) public {
        require(bytes(farmers[msg.sender].name).length == 0, "Farmer already registered");

        Farmer storage f = farmers[msg.sender];
        f.name = _name;
        f.location = _location;
        f.reputationScore = 0;
        f.isVetted = false;
        f.isEligible = false;

        farmerList.push(msg.sender);
        emit FarmerRegistered(msg.sender, _name, _location);
    }

    function vetFarmer(address _farmer, uint _score) public onlyAdmin {
        require(bytes(farmers[_farmer].name).length > 0, "Farmer not registered");

        farmers[_farmer].reputationScore = _score;
        farmers[_farmer].isVetted = true;
        farmers[_farmer].isEligible = _score >= 70;

        emit FarmerVetted(_farmer, _score, farmers[_farmer].isEligible);
    }

    
}
