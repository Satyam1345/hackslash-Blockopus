// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancerPlatform {
    // Owner of the contract
    address public owner;

    // Enumeration for project status
    enum ProjectStatus { Open, InProgress, Completed, Cancelled }

    // Struct to represent a freelancer
    struct Freelancer {
        address freelancerAddress;
        string skills;
        bool isRegistered;
    }
    // Struct to represent a client
    struct Client {
        address clientAddress;
        bool isRegistered;
    }
    // Struct to represent a project
    struct Project {
    address client;
    address freelancer;
    string description;
    uint256 budget;
    ProjectStatus status;
    uint256 creationTime;
    uint256 completionTime;
}


    // Mapping of freelancer addresses to Freelancer structs
    mapping(address => Freelancer) public freelancers;

    // Mapping of client addresses to Client structs
    mapping(address => Client) public clients;


    // Array to store Project structs
    Project[] public projects;

    // Mapping to track deposits made by users
    mapping(address => uint256) public deposits;

    // Events to log important actions
    event FreelancerRegistered(address indexed freelancerAddress, string skills);
    event ProjectCreated(address indexed client, address indexed freelancer, string description, uint256 budget, uint256 projectId);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event PaymentReleased(uint256 indexed projectId, uint256 amount);    
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    // Event to log client registration
    event ClientRegistered(address indexed clientAddress);

    // Modifier to restrict access to the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Constructor to set the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    // Function for freelancers to register themselves
    function registerFreelancer(string memory _skills) external {
        require(!freelancers[msg.sender].isRegistered, "Freelancer already registered");

        freelancers[msg.sender] = Freelancer(msg.sender, _skills, true);
        emit FreelancerRegistered(msg.sender, _skills);
    }

    // Function for clients to register themselves
    function registerClient() external {
        require(!clients[msg.sender].isRegistered, "Client already registered");

        clients[msg.sender] = Client(msg.sender, true);
        emit ClientRegistered(msg.sender);
    }


    // Function for clients to create a new project
    function createProject(address _freelancer, string memory _description, uint256 _budget) external {
    require(freelancers[_freelancer].isRegistered, "Freelancer is not registered");

    projects.push(Project(msg.sender, _freelancer, _description, _budget, ProjectStatus.Open, block.timestamp, 0));
    emit ProjectCreated(msg.sender, _freelancer, _description, _budget, 0);
    }


//Function to change project status
    function changeProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external onlyOwner {
    require(_projectId < projects.length, "Invalid project ID");

    projects[_projectId].status = _newStatus;

    if (_newStatus == ProjectStatus.Completed) {
        projects[_projectId].completionTime = block.timestamp;
    }

    emit ProjectStatusChanged(_projectId, _newStatus);
}

// Function to handle the release of payments
function releasePayment(uint256 _projectId, uint256 _amount) external onlyOwner {
    require(_projectId < projects.length, "Invalid project ID");
    require(projects[_projectId].status == ProjectStatus.Completed, "Project not completed");
    require(_amount <= projects[_projectId].budget, "Invalid payment amount");

    payable(projects[_projectId].freelancer).transfer(_amount);
    emit PaymentReleased(_projectId, _amount);
}

    // Function for users to deposit funds into the escrow
    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Function for users to withdraw funds from the escrow
    function withdraw(uint256 _amount) external {
        require(deposits[msg.sender] >= _amount, "Insufficient funds");
        deposits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }
}
