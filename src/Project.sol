// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IUserRegistry.sol";
import "./EAS/Attester.sol";

struct ProjectData {
    string name;
    string description;
    bool searchingFunding;
    address userContract;
    uint256 fundingGoal;
    uint256 fundedAmount;
    string[] rolesNeeded;
}

// Projects will inherit from Safe Smart Contract Wallet
contract Project {
    ProjectData s_ProjectInfo;

    address private s_projectOwner;
    IUserRegistry private s_userContract;
    address[] private s_teamMembers;
    address[] private s_investors;

    mapping(address => uint256) private s_investorAmounts;
    mapping(address => bool) private s_projectManager;
    mapping(address => uint256) private s_merit;

    event managerAdded(address manager);

    error Project__NotOwner();
    error Project__NotManager();
    error Project__NotDaoUser();

    modifier onlyUser(address _user) {
        s_userContract.isUser(_user);
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != s_projectOwner) {
            revert Project__NotOwner();
        }
        _;
    }

    modifier onlyManager() {
        if (
            msg.sender != s_projectOwner || s_projectManager[msg.sender] != true
        ) {
            revert Project__NotManager();
        }
        _;
    }

    // @dev This constructor is called by ProjectFactory
    constructor(address _projectOwner, ProjectData memory _projectData) {
        s_projectOwner = _projectOwner;
        s_userContract = IUserRegistry(_projectData.userContract);
        s_ProjectInfo.name = _projectData.name;
        s_ProjectInfo.description = _projectData.description;
        s_ProjectInfo.searchingFunding = _projectData.searchingFunding;
        s_ProjectInfo.fundingGoal = _projectData.fundingGoal;
        s_ProjectInfo.fundedAmount = _projectData.fundedAmount;
        s_ProjectInfo.rolesNeeded = _projectData.rolesNeeded;
    }

    function addManager(address _manager) public onlyManager {
        s_projectManager[_manager] = true;
        emit managerAdded(_manager);
    }

    function applyForRole() public onlyUser(msg.sender) {
        // this function should add application on queue for manager to aprove
        // if manager aprove it, then add user to teamMembers
    }

    // unfinished
    function invest(uint256 _amount) public payable {
        // This function should when investing on a project
        // first check funds if it can pay it.
        // second put this proposal in queue until owner aprobes it
        // third owner aproves it and the funds are transfered to the project
        // add investor to owner list (owner of )

        // require(_amount > 0, "Amount must be greater than 0");
        // require(_amount <= ERC20 USDC balance of msg.sender, "Amount must be less than balance of msg.sender");

        s_investors.push(msg.sender);
        s_investorAmounts[msg.sender] = _amount;

        // ERC20 USDC take amount from msg.sender

        s_ProjectInfo.fundedAmount += _amount;
    }

    /*
     *   Utility Functions
     */

    /*
     *   Getter Functions
     */

    function getFundGoal() public view returns (uint256) {
        return s_ProjectInfo.fundingGoal;
    }

    function getTeamMembers() public view returns (address[] memory) {
        return s_teamMembers;
    }

    function getInvestors() public view returns (address[] memory) {
        return s_investors;
    }

    function getFundedAmount() public view returns (uint256) {
        return s_ProjectInfo.fundedAmount;
    }

    function getProjectInfo() public view returns (ProjectData memory) {
        return s_ProjectInfo;
    }
}
