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

    // Vendor declares goods imported for sale
    function declareGoods(string memory _description, uint256 _quantity) public onlyRegisteredVendor {
        require(_quantity > 0, "Quantity must be positive");
        goodsCount++;
        goodsList[goodsCount] = Goods({
            description: _description,
            quantity: _quantity,
            sold: false
        });

        emit GoodsDeclared(msg.sender, goodsCount, _description, _quantity);
    }

    // Record sale of goods to buyer
    function recordSale(uint256 _goodsId, address _buyer) public onlyRegisteredVendor {
        require(_goodsId > 0 && _goodsId <= goodsCount, "Invalid goods ID");
        Goods storage item = goodsList[_goodsId];
        require(!item.sold, "Goods already sold");

        item.sold = true;
        goodsSales[_goodsId].push(Sale({
            buyer: _buyer,
            goodsId: _goodsId,
            timestamp: block.timestamp
        }));

        emit GoodsSold(msg.sender, _goodsId, _buyer);
    }

    // Raise dispute by vendor
    function raiseDispute(string memory _issue) public onlyRegisteredVendor {
        Dispute storage newDispute = disputes.push();
        newDispute.vendor = msg.sender;
        newDispute.issue = _issue;
        newDispute.resolved = false;
        newDispute.resolutionVotesYes = 0;
        newDispute.resolutionVotesNo = 0;

        emit DisputeRaised(disputes.length - 1, msg.sender, _issue);
    }

    // Voting on dispute resolution by market authority or designated committee
    function voteDispute(uint256 _disputeId, bool _voteYes) public onlyMarketAuthority {
        require(_disputeId < disputes.length, "Invalid dispute ID");
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "Dispute already resolved");
        require(!dispute.voted[msg.sender], "Already voted");

        dispute.voted[msg.sender] = true;
        if (_voteYes) {
            dispute.resolutionVotesYes++;
        } else {
            dispute.resolutionVotesNo++;
        }

        // Simple majority resolution example
        if (dispute.resolutionVotesYes + dispute.resolutionVotesNo >= 3) { // e.g., 3 votes needed
            dispute.resolved = true;
            bool outcome = dispute.resolutionVotesYes > dispute.resolutionVotesNo;
            emit DisputeResolved(_disputeId, outcome);
            // Implement outcome effects here (e.g., penalties, reinstatement)
        }
    }

    // Deactivate vendor (e.g., penalty or suspension)
    function deactivateVendor(address _vendor) public onlyMarketAuthority {
        require(vendors[_vendor].registered, "Vendor not registered");
        vendors[_vendor].active = false;
    }

    // Reactivate vendor
    function reactivateVendor(address _vendor) public onlyMarketAuthority {
        require(vendors[_vendor].registered, "Vendor not registered");
        vendors[_vendor].active = true;
    }

    // Get vendor info
    function getVendor(address _vendor) public view returns (string memory, uint256, bool) {
        Vendor memory v = vendors[_vendor];
        return (v.name, v.stallNumber, v.active);
    }
}
