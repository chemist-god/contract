// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FarmerRegistry
 * @dev This contract acts as a secure on-chain registry for verified farmers.
 * It is an essential component for ensuring that only legitimate farmers can
 * create and manage projects within the ecosystem. Access is restricted to the owner.
 */
contract FarmerRegistry is Ownable {
    mapping(address => bool) public isVetted;

    constructor(address initialOwner) Ownable(initialOwner) {}

    /* Vets a farmer by adding their address to the registry.*/
    function vetFarmer(address _farmer) public onlyOwner {
        require(_farmer != address(0), "Farmer address cannot be zero");
        isVetted[_farmer] = true;
    }
}

/* This is the core escrow contract for a single farming project. */
contract ProjectEscrow {
    // --- State Variables ---
    address public immutable farmer;
    address public immutable projectAdmin;
    uint256 public immutable fundingGoal;
    uint256 public immutable fundingDeadline;
    uint256 public immutable farmingStartTimestamp;
    IERC20 public immutable token;
    uint256 public immutable expectedROIPercentage;
    

    uint256 public totalPledged;
    mapping(address => uint256) public investors;
    address[] private investorAddresses; // Track investors for iteration
    
    uint256[] public milestoneAmounts;
    uint256 public currentMilestoneIndex;
    
    mapping(uint256 => bool) public milestoneProofsSubmitted;
    string[] public milestoneProofCIDs;
    
    uint256 public totalReturnsDeposited;
    mapping(address => uint256) public returnsBalances;

    bool private locked;

    enum ProjectState {
        Ongoing,
        Funded,
        Canceled,
        Completed
    }
    ProjectState public projectState;

    /* Events */
    event InvestmentMade(address indexed investor, uint256 amount);
    event FundingSuccessful();
    event MilestoneProofSubmitted(uint256 indexed milestoneIndex, string proofCid);
    event MilestonePaid(uint256 indexed milestoneIndex);
    event ReturnsDeposited(uint256 amount);
    event ReturnsClaimed(address indexed investor, uint256 amount);
    event ProjectCanceled();
    event ProjectCompleted();

    /* Modifiers */
    modifier onlyFarmer() {
        require(msg.sender == farmer, "Only the farmer can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == projectAdmin, "Only the project admin can call this function.");
        _;
    }

    modifier ongoing() {
        require(projectState == ProjectState.Ongoing, "Project is not ongoing.");
        _;
    }

    modifier nonReentrant() {
    require(!locked, "Reentrant call");
    locked = true;
    _;
    locked = false;
}


    constructor(
        address _farmer,
        address _projectAdmin,
        uint256 _fundingGoal,
        uint256 _fundingDeadline,
        uint256 _farmingStartTimestamp,
        uint256[] memory _milestoneAmounts,
        address _token,
        uint256 _expectedROIPercentage 
    ) {
        farmer = _farmer;
        projectAdmin = _projectAdmin;
        fundingGoal = _fundingGoal;
        fundingDeadline = _fundingDeadline;
        farmingStartTimestamp = _farmingStartTimestamp;
        milestoneAmounts = _milestoneAmounts;
        token = IERC20(_token);
        expectedROIPercentage = _expectedROIPercentage;
        projectState = ProjectState.Ongoing;
        currentMilestoneIndex = 0;
        
        require(_farmingStartTimestamp > _fundingDeadline, "Farming start must be after funding deadline.");
        
     
        uint256 totalMilestoneAmount = 0;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            totalMilestoneAmount += _milestoneAmounts[i];
        }
        require(totalMilestoneAmount == _fundingGoal, "Milestone sum must equal funding goal.");

    }

    
    
    /* Allows investors to fund the project by sending stablecoin tokens. */

    function invest(uint256 amount) public ongoing nonReentrant {
        require(block.timestamp <= fundingDeadline, "Funding deadline has passed.");
        require(amount > 0, "Amount must be greater than zero.");
        
        
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        
        if (investors[msg.sender] == 0) {
            investorAddresses.push(msg.sender);
        }
        
        investors[msg.sender] += amount;
        totalPledged += amount;

        emit InvestmentMade(msg.sender, amount);

        if (totalPledged >= fundingGoal) {
            projectState = ProjectState.Funded;
            emit FundingSuccessful();
        }
    }

    /* Allows the farmer to submit proof of work for the current milestone. */

    function submitMilestoneProof(string memory _proofCid) public onlyFarmer {
        require(currentMilestoneIndex < milestoneAmounts.length, "All milestones have been submitted.");
        require(!milestoneProofsSubmitted[currentMilestoneIndex], "Proof for this milestone already submitted.");
        
        milestoneProofCIDs.push(_proofCid);
        milestoneProofsSubmitted[currentMilestoneIndex] = true;
        
        emit MilestoneProofSubmitted(currentMilestoneIndex, _proofCid);
    }


    /* Releases funds for the current milestone. This requires a multi-sig approval. */

function releaseMilestoneFunds(bytes memory _farmerSignature) public onlyAdmin nonReentrant {
    require(projectState == ProjectState.Funded, "Project is not funded.");
    require(milestoneProofsSubmitted[currentMilestoneIndex], "Proof not submitted for this milestone.");
    require(block.timestamp >= farmingStartTimestamp, "Farming season hasn't started yet.");
    
    // Mock multi-sig validation
 require(_farmerSignature.length == 65, "Invalid signature format");

    uint256 milestoneAmount = milestoneAmounts[currentMilestoneIndex];
    require(token.transfer(farmer, milestoneAmount), "Token transfer to farmer failed.");
    
    milestoneProofsSubmitted[currentMilestoneIndex] = false;
    currentMilestoneIndex++;
    
    emit MilestonePaid(currentMilestoneIndex - 1); // Fix: emit correct milestone index
    
    if (currentMilestoneIndex == milestoneAmounts.length) {
        projectState = ProjectState.Completed;
        emit ProjectCompleted();
    }
}

function getExpectedReturns(address investor) public view returns (uint256) {
    if (investors[investor] == 0) return 0;
    
    uint256 principal = investors[investor];
    uint256 roi = (principal * expectedROIPercentage) / 100;
    return principal + roi; // Total expected return (capital + interest)
}

    /* Allows the farmer to deposit the ROI funds for investors to claim. */
    
    function payReturns(uint256 amount) public payable onlyFarmer nonReentrant {
        require(projectState == ProjectState.Completed, "Project is not completed.");
        require(amount > 0, "Amount must be greater than zero.");
        
         require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
         totalReturnsDeposited += amount;
        for (uint256 i = 0; i < investorAddresses.length; i++) {
        address investorAddress = investorAddresses[i];
        uint256 share = (investors[investorAddress] * amount) / fundingGoal; // Use 'amount' not 'totalReturnsDeposited'
        returnsBalances[investorAddress] += share;
        }

        emit ReturnsDeposited(amount);
    }
    
    /* Allows an investor to claim their proportional share of the ROI. */
    function claimReturns() public nonReentrant {
        require(projectState == ProjectState.Completed, "Project is not completed.");
        uint256 amountToClaim = returnsBalances[msg.sender];
        require(amountToClaim > 0, "No returns to claim.");
        
        returnsBalances[msg.sender] = 0;
        require(token.transfer(msg.sender, amountToClaim), "Token transfer to investor failed.");
        
        emit ReturnsClaimed(msg.sender, amountToClaim);
    }

    /* Allows the admin to cancel the project and refund all investors. */  
    function cancelProject() public onlyAdmin nonReentrant {
        require(projectState == ProjectState.Ongoing, "Project cannot be canceled in its current state.");
        
        projectState = ProjectState.Canceled;
        emit ProjectCanceled();
        
     
        for (uint256 i = 0; i < investorAddresses.length; i++) {
            address investorAddress = investorAddresses[i];
            if (investors[investorAddress] > 0) {
                require(token.transfer(investorAddress, investors[investorAddress]), "Refund failed.");
                investors[investorAddress] = 0;
            }
        }
    }
    
    /* Allows anyone to trigger a refund for all investors if the project is not funded*/
    function refundInvestorsIfUnfunded() public nonReentrant {
        require(projectState == ProjectState.Ongoing, "Project is not in a state to be refunded.");
        require(block.timestamp > fundingDeadline, "Funding deadline has not passed yet.");
        require(totalPledged < fundingGoal, "Funding goal has been met.");
        
        projectState = ProjectState.Canceled;
        emit ProjectCanceled();
       
        for (uint256 i = 0; i < investorAddresses.length; i++) {
            address investorAddress = investorAddresses[i];
            if (investors[investorAddress] > 0) {
                require(token.transfer(investorAddress, investors[investorAddress]), "Refund failed.");
                investors[investorAddress] = 0;
            }
        }
    }
}


/* This is the entry point for creating new farming projects. */
 
contract FarmingProjectFactory {
    FarmerRegistry public immutable farmerRegistry;
    address public immutable projectAdmin;
    ProjectEscrow[] public deployedProjects;
    
    event ProjectCreated(address indexed newProject, address indexed farmer, uint256 fundingGoal);
    
    constructor(address _farmerRegistry, address _projectAdmin) {
        require(_farmerRegistry != address(0), "Registry address cannot be zero.");
        require(_projectAdmin != address(0), "Admin address cannot be zero.");
        farmerRegistry = FarmerRegistry(_farmerRegistry);
        projectAdmin = _projectAdmin;
    }
    
    /* Deploys a new ProjectEscrow contract instance. */

    function createProject(
        uint256 _fundingGoal,
        uint256[] memory _milestoneAmounts,
        uint256 _fundingDeadline,
        uint256 _farmingStartTimestamp,
        address _token,
        uint256 _expectedROIPercentage
    ) public {
        require(farmerRegistry.isVetted(msg.sender), "Caller is not a vetted farmer.");
        require(block.timestamp < _farmingStartTimestamp, "Farming season has already started.");
        
        ProjectEscrow newProject = new ProjectEscrow(
            msg.sender,
            projectAdmin,
            _fundingGoal,
            _fundingDeadline,
            _farmingStartTimestamp,
            _milestoneAmounts,
            _token,
            _expectedROIPercentage
        );
        deployedProjects.push(newProject);
        
        emit ProjectCreated(address(newProject), msg.sender, _fundingGoal);
    }
}
