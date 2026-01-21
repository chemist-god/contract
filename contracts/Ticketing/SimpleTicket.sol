// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SimpleTicketSystem {
    
    // ============ STRUCTS ============
    struct Event {
        uint256 id;
        address organizer;
        string name;
        uint256 startTime;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 ticketsSold;
        bool isCanceled;
    }
    
    struct Ticket {
        uint256 id;
        uint256 eventId;
        address owner;
        bool isUsed;
        uint256 purchasePrice;
    }
    
    // ============ STATE VARIABLES ============
    uint256 private eventCounter;
    uint256 private ticketCounter;
    
    mapping(uint256 => Event) public events;
    mapping(uint256 => Ticket) public tickets;
    mapping(address => uint256[]) public userTickets;
    mapping(uint256 => uint256[]) public eventTickets;
    
    
}