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
    
    function cancelEvent(uint256 eventId) 
        external 
        eventExists(eventId) 
        onlyOrganizer(eventId) 
    {
        require(!events[eventId].isCanceled, "Already canceled");
        events[eventId].isCanceled = true;
        emit EventCanceled(eventId);
    }
    
    // ============ TICKET PURCHASE ============
    function buyTicket(uint256 eventId) 
        external 
        payable 
        eventExists(eventId) 
        notCanceled(eventId) 
    {
        Event storage eventInfo = events[eventId];
        
        require(msg.value == eventInfo.ticketPrice, "Wrong price");
        require(block.timestamp < eventInfo.startTime, "Event started");
        require(eventInfo.ticketsSold < eventInfo.maxTickets, "Sold out");
        
        // Create ticket
        ticketCounter++;
        
        tickets[ticketCounter] = Ticket({
            id: ticketCounter,
            eventId: eventId,
            owner: msg.sender,
            isUsed: false,
            purchasePrice: msg.value
        });
        
        // Update counts
        eventInfo.ticketsSold++;
        userTickets[msg.sender].push(ticketCounter);
        eventTickets[eventId].push(ticketCounter);
        
        // Transfer funds to organizer
        payable(eventInfo.organizer).transfer(msg.value);
        
        emit TicketPurchased(ticketCounter, msg.sender, eventId);
    }
    
    // ============ TICKET MANAGEMENT ============
    function useTicket(uint256 ticketId) external {
        Ticket storage ticket = tickets[ticketId];
        require(ticket.owner == msg.sender, "Not owner");
        require(!ticket.isUsed, "Already used");
        
        Event storage eventInfo = events[ticket.eventId];
        require(!eventInfo.isCanceled, "Event canceled");
        require(block.timestamp >= eventInfo.startTime, "Event not started yet");
        
        ticket.isUsed = true;
        emit TicketUsed(ticketId, msg.sender);
    }
    
    function transferTicket(uint256 ticketId, address newOwner) external {
        Ticket storage ticket = tickets[ticketId];
        require(ticket.owner == msg.sender, "Not owner");
        require(!ticket.isUsed, "Ticket used");
        
        Event storage eventInfo = events[ticket.eventId];
        require(block.timestamp < eventInfo.startTime, "Event started");
        
        // Remove from old owner
        _removeFromUserTickets(msg.sender, ticketId);
        
        // Add to new owner
        ticket.owner = newOwner;
        userTickets[newOwner].push(ticketId);
    }
    
    
}