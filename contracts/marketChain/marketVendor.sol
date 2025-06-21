// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MarketWomenVendorManagement {
    address public marketAuthority;

    constructor() {
        marketAuthority = msg.sender; // Market admin deploys contract
    }

    struct Vendor {
        string name;
        address vendorAddress;
        bool registered;
        uint256 stallNumber;
        bool active;
    }

    struct Goods {
        string description;
        uint256 quantity;
        bool sold;
    }

    struct Sale {
        address buyer;
        uint256 goodsId;
        uint256 timestamp;
    }

    struct Dispute {
        address vendor;
        string issue;
        bool resolved;
        uint256 resolutionVotesYes;
        uint256 resolutionVotesNo;
        mapping(address => bool) voted;
    }

    uint256 public totalStalls = 100; // Example total stalls
    mapping(address => Vendor) public vendors;
    mapping(uint256 => Goods) public goodsList;
    uint256 public goodsCount = 0;

    mapping(address => uint256) public vendorStall; // vendor address to stall number
    mapping(uint256 => Sale[]) public goodsSales; // goodsId to sales

    // Dispute management
    Dispute[] public disputes;

    // Events
    event VendorRegistered(address vendor, string name, uint256 stallNumber);
    event GoodsDeclared(address vendor, uint256 goodsId, string description, uint256 quantity);
    event GoodsSold(address vendor, uint256 goodsId, address buyer);
    event DisputeRaised(uint256 disputeId, address vendor, string issue);
    event DisputeResolved(uint256 disputeId, bool outcome);

    modifier onlyMarketAuthority() {
        require(msg.sender == marketAuthority, "Only market authority allowed");
        _;
    }

    modifier onlyRegisteredVendor() {
        require(vendors[msg.sender].registered && vendors[msg.sender].active, "Not an active registered vendor");
        _;
    }

    // Register vendor and assign stall if available
    function registerVendor(string memory _name) public {
        require(!vendors[msg.sender].registered, "Already registered");
        // Find first available stall
        uint256 assignedStall = 0;
        bool stallFound = false;
        for (uint256 i = 1; i <= totalStalls; i++) {
            bool occupied = false;
            // Check if stall is occupied
            for (address addr = address(0); addr <= address(type(uint160).max); addr = address(uint160(addr) + 1)) {
                if (vendors[addr].stallNumber == i && vendors[addr].active) {
                    occupied = true;
                    break;
                }
            }
            if (!occupied) {
                assignedStall = i;
                stallFound = true;
                break;
            }
        }
        require(stallFound, "No stalls available");

        vendors[msg.sender] = Vendor({
            name: _name,
            vendorAddress: msg.sender,
            registered: true,
            stallNumber: assignedStall,
            active: true
        });
        vendorStall[msg.sender] = assignedStall;

        emit VendorRegistered(msg.sender, _name, assignedStall);
    }

    
}
