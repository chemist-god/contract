// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SalesFlow {
    address public owner;

    struct Prospect {
        string name;
        string contact;
        bool interacted;
        bool dealClosed;
        uint256 reward;
    }

    mapping(uint256 => Prospect) public prospects;
    uint256 public prospectCount;

    event ProspectAdded(uint256 indexed id, string name);
    event InteractionLogged(uint256 indexed id);
    event DealClosed(uint256 indexed id, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addProspect(string memory _name, string memory _contact) public onlyOwner {
        prospects[prospectCount] = Prospect(_name, _contact, false, false, 0);
        emit ProspectAdded(prospectCount, _name);
        prospectCount++;
    }

    function logInteraction(uint256 _id) public onlyOwner {
        require(!prospects[_id].interacted, "Already interacted");
        prospects[_id].interacted = true;
        emit InteractionLogged(_id);
    }

    function closeDeal(uint256 _id, uint256 _reward) public onlyOwner {
        require(prospects[_id].interacted, "Interaction not logged");
        require(!prospects[_id].dealClosed, "Deal already closed");
        prospects[_id].dealClosed = true;
        prospects[_id].reward = _reward;
        emit DealClosed(_id, _reward);
    }

    function getProspect(uint256 _id) public view returns (Prospect memory) {
        return prospects[_id];
    }
}
