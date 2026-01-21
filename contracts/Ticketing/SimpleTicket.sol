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
    
    // ============ EVENTS ============
    event EventCreated(uint256 indexed eventId, address organizer, string name);
    event TicketPurchased(uint256 indexed ticketId, address buyer, uint256 eventId);
    event TicketUsed(uint256 indexed ticketId, address user);
    event EventCanceled(uint256 indexed eventId);
    
    // ============ MODIFIERS ============
    modifier onlyOrganizer(uint256 eventId) {
        require(events[eventId].organizer == msg.sender, "Not organizer");
        _;
    }
    
    modifier eventExists(uint256 eventId) {
        require(events[eventId].organizer != address(0), "Event not found");
        _;
    }
    
    modifier notCanceled(uint256 eventId) {
        require(!events[eventId].isCanceled, "Event canceled");
        _;
    }
    
    // ============ EVENT MANAGEMENT ============
    function createEvent(
        string memory name,
        uint256 startTime,
        uint256 ticketPrice,
        uint256 maxTickets
    ) external returns (uint256) {
        require(startTime > block.timestamp, "Start time must be future");
        require(maxTickets > 0, "Must have tickets");
        
        eventCounter++;
        
        events[eventCounter] = Event({
            id: eventCounter,
            organizer: msg.sender,
            name: name,
            startTime: startTime,
            ticketPrice: ticketPrice,
            maxTickets: maxTickets,
            ticketsSold: 0,
            isCanceled: false
        });
        
        emit EventCreated(eventCounter, msg.sender, name);
        return eventCounter;
    }
    
  
}