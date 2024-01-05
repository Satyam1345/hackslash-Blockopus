// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

contract FreelancerPlatform {
    address public owner;

    enum ProjectStatus { Open, InProgress, Completed, Cancelled }

    struct Freelancer {
        address freelancerAddress;
        string skills;
        bool isRegistered;
    }

    struct Project {
        address client;
        address freelancer;
        string description;
        uint256 budget;
        ProjectStatus status;
    }

    mapping(address => Freelancer) public freelancers;
    Project[] public projects;
    mapping(address => uint256) public deposits;

    event FreelancerRegistered(address indexed freelancerAddress, string skills);
    event ProjectCreated(address indexed client, address indexed freelancer, string description, uint256 budget);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event PaymentReleased(uint256 indexed projectId, uint256 amount);
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerFreelancer(string memory _skills) external {
        require(!freelancers[msg.sender].isRegistered, "Freelancer already registered");

        freelancers[msg.sender] = Freelancer(msg.sender, _skills, true);
        emit FreelancerRegistered(msg.sender, _skills);
    }

    function createProject(address _freelancer, string memory _description, uint256 _budget) external {
        require(freelancers[_freelancer].isRegistered, "Freelancer is not registered");

        projects.push(Project(msg.sender, _freelancer, _description, _budget, ProjectStatus.Open));
        emit ProjectCreated(msg.sender, _freelancer, _description, _budget);
    }

    function changeProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external onlyOwner {
        require(_projectId < projects.length, "Invalid project ID");

        projects[_projectId].status = _newStatus;
        emit ProjectStatusChanged(_projectId, _newStatus);
    }

    function releasePayment(uint256 _projectId, uint256 _amount) external onlyOwner {
        require(_projectId < projects.length, "Invalid project ID");
        require(projects[_projectId].status == ProjectStatus.Completed, "Project not completed");
        require(_amount <= projects[_projectId].budget, "Invalid payment amount");

        payable(projects[_projectId].freelancer).transfer(_amount);
        emit PaymentReleased(_projectId, _amount);
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        require(deposits[msg.sender] >= _amount, "Insufficient funds");
        deposits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }
}
