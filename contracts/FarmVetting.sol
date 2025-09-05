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

    function registerFarmer(string memory _name, string memory _location) public {
        Farmer storage f = farmers[msg.sender];
        f.name = _name;
        f.location = _location;
        f.reputationScore = 0;
        f.isVetted = false;
        f.isEligible = false;
        farmerList.push(msg.sender);
    }

    function vetFarmer(address _farmer, uint _score) public onlyAdmin {
        require(bytes(farmers[_farmer].name).length > 0, "Farmer not registered");
        farmers[_farmer].reputationScore = _score;
        farmers[_farmer].isVetted = true;
        farmers[_farmer].isEligible = _score >= 70; // Threshold for eligibility
    }

    function getFarmer(address _farmer) public view returns (
        string memory name,
        string memory location,
        uint reputationScore,
        bool isVetted,
        bool isEligible
    ) {
        Farmer memory f = farmers[_farmer];
        return (f.name, f.location, f.reputationScore, f.isVetted, f.isEligible);
    }

    function getAllFarmers() public view returns (address[] memory) {
        return farmerList;
    }
}
