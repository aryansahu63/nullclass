// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdTank {
    // --- STRUCT AND STATE VARIABLES ---

    struct Project {
        uint256 id;
        address payable creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 deadline;
        uint256 fundsRaised;
        bool finalized;
        bool failed;
    }

    uint256 public projectCount;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions;

    // ENHANCEMENT 1: Admin and Creator Management
    address public admin;
    mapping(address => bool) public isCreator;
    
    // ENHANCEMENT 2: Tracking total funded/failed projects
    uint256 public successfullyFundedCount;
    uint256 public failedToFundCount;

    // --- EVENTS ---

    event ProjectCreated(uint256 id, address creator, string title, uint256 goal, uint256 deadline);
    event Funded(uint256 id, address funder, uint256 amount);
    event Withdrawn(uint256 id, address creator, uint256 amount);
    event Refunded(uint256 id, address funder, uint256 amount);
    event Finalized(uint256 id, bool successful);
    event ExcessRefunded(uint256 id, address funder, uint256 excess); // For enhancement
    event CommitmentWithdrawn(uint256 id, address funder, uint256 amount); // For enhancement
    event CreatorAdded(address creator);
    event CreatorRemoved(address creator);

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyCreator() {
        require(isCreator[msg.sender], "Only registered creators can call this function");
        _;
    }

    // --- CONSTRUCTOR ---
    // ENHANCEMENT 1: Set contract deployer as Admin
    constructor() {
        admin = msg.sender;
    }

    // --- ADMIN FUNCTIONS ---
    // ENHANCEMENT 1: Admin can add and remove creators
    function addCreator(address _creator) external onlyAdmin {
        require(_creator != address(0), "Invalid address");
        isCreator[_creator] = true;
        emit CreatorAdded(_creator);
    }

    function removeCreator(address _creator) external onlyAdmin {
        require(_creator != admin, "Cannot remove admin status");
        isCreator[_creator] = false;
        emit CreatorRemoved(_creator);
    }

    // --- CROWDTANK CORE FUNCTIONS ---

    // ENHANCEMENT 1: Restrict createProject to only added creators
    function createProject(
        string memory _title,
        string memory _description,
        uint256 _goalAmount, 
        uint256 _durationInMinutes
    ) external onlyCreator {
        require(_goalAmount > 0, "Goal must be greater than 0");
        require(_durationInMinutes > 0, "Duration must be > 0");

        projectCount++;
        uint256 deadline = block.timestamp + (_durationInMinutes * 1 minutes);

        projects[projectCount] = Project({
            id: projectCount,
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            deadline: deadline,
            fundsRaised: 0,
            finalized: false,
            failed: false
        });

        emit ProjectCreated(projectCount, msg.sender, _title, _goalAmount, deadline);
    }

    // ENHANCEMENT 3: Modify fundProject to return extra funds
    function fundProject(uint256 _id) external payable {
        Project storage project = projects[_id];
        require(block.timestamp < project.deadline, "Project deadline passed");
        require(msg.value > 0, "Must send ETH");

        uint256 newFundsRaised = project.fundsRaised + msg.value;
        uint256 contributionAmount = msg.value;
        uint256 excess = 0;

        // Check if the goal is exceeded
        if (newFundsRaised > project.goalAmount) {
            // Calculate how much is needed to meet the goal exactly
            uint256 needed = project.goalAmount - project.fundsRaised;
            excess = msg.value - needed;
            contributionAmount = needed;
            newFundsRaised = project.goalAmount; // Cap the raised funds at the goal
            
            // Refund the excess to the sender immediately
            (bool sent, ) = payable(msg.sender).call{value: excess}("");
            require(sent, "Excess refund failed");
            emit ExcessRefunded(_id, msg.sender, excess);
        }

        project.fundsRaised = newFundsRaised;
        contributions[_id][msg.sender] += contributionAmount;
        
        emit Funded(_id, msg.sender, msg.value - excess); // Log the actual amount contributed
    }

    function finalizeProject(uint256 _id) external {
        Project storage project = projects[_id];
        require(block.timestamp >= project.deadline, "Deadline not reached");
        require(!project.finalized, "Already finalized");

        if (project.fundsRaised >= project.goalAmount) {
            uint256 amount = project.fundsRaised;
            project.fundsRaised = 0;
            
            // ENHANCEMENT 2: Update successful count
            successfullyFundedCount++; 
            
            (bool sent, ) = project.creator.call{value: amount}("");
            require(sent, "Transfer to creator failed");
            emit Withdrawn(_id, project.creator, amount);
        } else {
            project.failed = true;
            
            // ENHANCEMENT 2: Update failed count
            failedToFundCount++;
        }

        project.finalized = true;
        emit Finalized(_id, !project.failed);
    }

    function refund(uint256 _id) external {
        Project storage project = projects[_id];
        require(project.failed, "Project not failed");
        uint256 amount = contributions[_id][msg.sender];
        require(amount > 0, "No funds to refund");

        contributions[_id][msg.sender] = 0;
        
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Refund transfer failed");
        emit Refunded(_id, msg.sender, amount);
    }
    
    // ENHANCEMENT 4: User withdrawing funds before the deadline
    function withdrawCommitment(uint256 _id) external {
        Project storage project = projects[_id];
        // Cannot withdraw if deadline is passed or if project is finalized
        require(block.timestamp < project.deadline, "Deadline reached or project finalized");
        require(!project.finalized, "Deadline reached or project finalized"); 
        
        uint256 amount = contributions[_id][msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        // Remove contribution from mapping and project's raised funds
        contributions[_id][msg.sender] = 0;
        project.fundsRaised -= amount; 
        
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Withdrawal transfer failed");
        emit CommitmentWithdrawn(_id, msg.sender, amount);
    }


    // --- READ-ONLY FUNCTIONS ---

    function getProject(uint256 _id)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256 goal,
            uint256 raised,
            uint256 deadline,
            bool finalized,
            bool failed
        )
    {
        Project memory p = projects[_id];
        return (p.id, p.creator, p.title, p.description, p.goalAmount, p.fundsRaised, p.deadline, p.finalized, p.failed);
    }
    
    // ENHANCEMENT 5: Add read-only function for funding percentage
    function getFundingPercentage(uint256 _id) external view returns (uint256 percentage) {
        Project memory p = projects[_id];
        require(p.goalAmount > 0, "Project does not exist or has no goal");
        
        // Use a multiplier of 100 for percentage calculation to avoid truncation
        percentage = (p.fundsRaised * 100) / p.goalAmount;
    }
}