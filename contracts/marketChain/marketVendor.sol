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

   
}
