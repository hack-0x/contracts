// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Merit is ERC20 {
    constructor() ERC20("Merit", "MERIT") {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        revert("Merit is not transferable");
    }
}

contract Hack0x is Ownable{

    enum UserType { CREATOR, BUIDLER, INVESTOR }

    enum ProjectLabel { DEFI, NFT, GAMING, METAVERSE, DAO, INFRASTRUCTURE, OTHER }

    enum PrizeDistributionType { EQUAL, MERIT }
   
    struct UserInfo {   // roles, skills - offchain
        UserType userType;
        address[] projects;
    }

    struct HackathonInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct Task {
        address taskCreator;
        address taskBuidler;
        uint8 taskValue;
        uint256 taskDeadline;
        bool taskCompleted;
    }

    struct OnboardingQuest {
        address questCreator;
        address questBuidler;
        uint256 questDeadline;
        bool questCompleted;
    }
    
    struct ProjectInfo {
        address SAFE;
        ProjectLabel[] labels;
        mapping(address => uint256) investors;
        address[] buidlers;
      //  address[] creators;
        mapping(address => bool) isCreator;
        mapping(address => string) joinRequests; // mapping of buidler address to link to their work
        uint256 hackathonId;
        PrizeDistributionType prizeDistributionType;
        uint256 predictiveValue;
        uint256 prize;
        Task[] tasks;
        bool closed;
    }

    Merit public immutable merit;

    mapping(address => UserInfo) public userInfos;
    HackathonInfo[] public hackathonInfos;
    mapping(address => ProjectInfo) public projectInfos;

    uint256 constant MAX_INT = 2**256 - 1;
    uint256 constant DAOSharePercentage = 40; // 40% of all prizes go to the DAO - have it changeable???

    modifier onlyCreator(address SAFE) {
        require(projectInfos[SAFE].isCreator[msg.sender], "User must be a creator");
        _;
    }

    modifier projectExists(address SAFE) {
        require(projectInfos[SAFE].creators.length > 0, "Project must exist");
        _;
    }

    modifier projectLive(address SAFE) {
        ProjectInfo project = projectInfos[SAFE];
        require(project.creators.length > 0, "Project must exist");
        require(hackathonInfos[project.hackathonId].endTimestamp > block.timestamp, "Project's hackathon must not have ended");
        _;
    }

    modifier projectClosed(address SAFE) {
        ProjectInfo project = projectInfos[SAFE];
        require(hackathonInfos[project.hackathonId].endTimestamp < block.timestamp, "Project's hackathon must have ended");//or not?
        require(project.closed, "Project must be closed");
        _;
    }

    constructor() {
        owner = msg.sender;
        merit = new Merit();
        createHackathon(0, MAX_INT); // hackathon 0 that means no hackathon
    }

    function createHackathon(uint256 startTimestamp, uint256 endTimestamp) public onlyOwner returns (uint256){
        require(startTimestamp < endTimestamp, "startTimestamp must be before endTimestamp");
        HackathonInfo memory hackathonInfo = HackathonInfo(startTimestamp, endTimestamp);
        hackathonInfos.push(hackathonInfo);
        return hackathonInfos.length - 1;
    }

    function joinDAO(UserType usertype) public {
        require(userInfos[msg.sender].userType == UserType(0), "User already joined");
        userInfos[msg.sender].userType = usertype;
    }

    function createProject(address SAFE, ProjectLabel[] memory labels, uint256 hackathonId, PrizeDistributionType prizeDistributionType, uint256 predictiveValue) public {
        require(userInfos[msg.sender].userType == UserType.CREATOR, "User must be a creator");
        require(hackathonInfos[hackathonId].endTimestamp > block.timestamp, "Hackathon must not have ended");
        require(projectInfos[SAFE].creators.length == 0, "Project already exists");
        require(SAFE != address(0), "SAFE address must be set");
        ProjectInfo memory projectInfo = ProjectInfo(SAFE, labels, new address[](0), new address[](0), new address[](0), hackathonId, prizeDistributionType, predictiveValue);
        projectInfos[SAFE] = projectInfo;
        projectInfos[SAFE].isCreator[msg.sender] = true;
        userInfos[msg.sender].projects.push(SAFE);
      //  merit._mint(msg.sender, prizeForCreatingProject); ?? 
    }

    function requestToJoinProject(address SAFE, string link) external projectExists(SAFE){
        require(userInfos[msg.sender].userType == UserType.BUIDLER, "user must be a buidler");

        ProjectInfo storage projectInfo = projectInfos[SAFE];
        projectInfo.joinRequests[msg.sender] = link;
    }

    function getJoinRequestLink(address SAFE, address buidler) external view returns (string memory) {
        return projectInfos[SAFE].joinRequests[buidler];
    }

    function approveJoinRequest(address SAFE, address buidler) external projectLive(SAFE) onlyCreator(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        require(project.joinRequests[buidler] != "", "buidler must have requested to join");
        project.buidlers.push(buidler);
        userInfos[buidler].projects.push(SAFE);
        delete project.joinRequests[buidler];
        //  merit._mint(msg.sender, prizeForJoiningProject); ?? 
    }

    function createTask(address SAFE, uint8 value, uint256 deadline) external projectLive(SAFE) onlyCreator(SAFE) returns (uint256) {
        ProjectInfo storage project = projectInfos[SAFE];
        Task memory task = Task(msg.sender, value, deadline, false);
        project.tasks.push(task);
        return project.tasks.length - 1;
    }

    function invest(address SAFE) external payable  { //projectLive(SAFE)?
        require(userInfos[msg.sender].userType == UserType.INVESTOR, "user must be an investor");
        ProjectInfo storage projectInfo = projectInfos[SAFE];
        projectInfo.investors.push(msg.sender);
        projectInfo.prize += msg.value; // ?
        //  merit._mint(msg.sender, msg.value); ?? 
    }

    function closeProject(address SAFE) external onlyCreator(SAFE) {
        _distributePrizeToDAO(SAFE);
        projectInfos[SAFE].closed = true;
    }

    function _distributePrizeToDAO(address SAFE) internal {
        ProjectInfo storage project = projectInfos[SAFE];
        uint256 DAOShare = project.prize * DAOSharePercentage / 100;
        project.prize -= DAOShare;
    }

    function withdraw(address SAFE) external projectClosed(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        require(project.prize > 0, "Project must have a prize");
        if (userInfos[msg.sender].userType == UserType.INVESTOR) {
            _withdrawInvestor(SAFE);
        } else if (userInfos[msg.sender].userType == UserType.BUIDLER) {
            _withdrawBuidler(SAFE);
        } else {
            _withdrawCreator(SAFE);
        }
    }

    function withdraw() external {
        require(userInfos[msg.sender].userType != UserType(0), "User has not joined the DAO");
        uint256 amount = merit.balanceOf(msg.sender) / merit.totalSupply() * address(this).balance; // ?
        
    }

}