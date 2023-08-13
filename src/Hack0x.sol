// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "./interfaces/IHack0xMerit.sol";
import "./Hack0xManifesto.sol";
import "./Hack0xDAOPrizePool.sol";
import "./EAS/Attesters/Attester.sol";
import "@openzeppelin-latest/contracts/access/Ownable.sol";

contract Hack0x is Ownable, Attester {
    enum UserType {
        CREATOR,
        BUIDLER,
        INVESTOR
    }

    enum ProjectLabel {
        DEFI,
        NFT,
        GAMING,
        METAVERSE,
        DAO,
        INFRASTRUCTURE,
        OTHER
    }

    enum PrizeDistributionType {
        EQUAL,
        MERIT
    }

    struct UserInfo {
        // roles, skills - offchain
        bool joined;
        address[] projects;
        UserType userType;
    }

    struct HackathonInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct Task {
        address taskCreator;
        address taskBuidler;
        address pickedUpBy;
        uint256 taskValue;
        uint256 taskDeadline;
        bool taskCompleted;
        bytes32 easUID;
    }

    struct OnboardingQuest {
        address questCreator;
        address questBuidler;
        uint256 questDeadline;
        bool questCompleted;
    }

    struct ProjectInfo {
        address SAFE;
        uint256 hackathonId;
        PrizeDistributionType prizeDistributionType;
        uint256 predictiveValue;
        uint256 prize;
        uint256 totalInvestment;
        address[] team;
        address[] creators;
        Task[] tasks;
        bool closed;
        mapping(address => string) joinRequests; // mapping of buidler address to link to their work
        mapping(address => bool) isCreator;
        mapping(address => bool) isBuidler;
        mapping(address => uint256) investors; // mapping of investor address to amount invested
    }

    IHack0xMerit public immutable merit;
    Hack0xManifesto public immutable manifesto;
    Hack0xDAOPrizePool public immutable prizePool;

    mapping(address => UserInfo) public userInfos;
    HackathonInfo[] public hackathonInfos;
    mapping(address => ProjectInfo) public projectInfos;

    uint256 constant MAX_INT = 2 ** 256 - 1;
    uint256 constant DAOSharePercentage = 40; // 40% of all prizes go to the DAO
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyCreator(address SAFE) {
        require(projectInfos[SAFE].isCreator[msg.sender], "User must be a creator");
        _;
    }

    modifier projectExists(address SAFE) {
        require(projectInfos[SAFE].creators.length > 0, "Project must exist");
        _;
    }

    modifier projectLive(address SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        require(project.creators.length > 0, "Project must exist");
        require(
            hackathonInfos[project.hackathonId].endTimestamp > block.timestamp,
            "Project's hackathon must not have ended"
        );
        _;
    }

    modifier projectClosed(address SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        require(
            hackathonInfos[project.hackathonId].endTimestamp < block.timestamp, "Project's hackathon must have ended"
        ); //or not?
        require(project.closed, "Project must be closed");
        _;
    }

    constructor(
        address EAS,
        address Hack0xMerit,
        bytes32 _attestTaskSchema,
        bytes32 _doneTaskSchema,
        bytes32 _projectCreationSchema,
        bytes32 _attestUserSchema
    )
        Attester(EAS, msg.sender, _attestTaskSchema, _doneTaskSchema, _projectCreationSchema, _attestUserSchema)
        Ownable()
    {
        // _owner = msg.sender;
        manifesto = new Hack0xManifesto(); // create manifesto token from within the contract, making this contract it's admin
        merit = IHack0xMerit(Hack0xMerit); // create merit token from within the contract, making this contract it's admin
        merit.grantRole(DEFAULT_ADMIN_ROLE, EAS); // grant EAS the ability to mint merit tokens
        prizePool = new Hack0xDAOPrizePool(address(merit)); // create DAO prize pool contract
        createHackathon(0, MAX_INT); // hackathon 0 that means no hackathon
    }

    function createHackathon(uint256 startTimestamp, uint256 endTimestamp) public onlyOwner returns (uint256) {
        require(startTimestamp < endTimestamp, "startTimestamp must be before endTimestamp");
        HackathonInfo memory hackathonInfo = HackathonInfo(startTimestamp, endTimestamp);
        hackathonInfos.push(hackathonInfo);
        return hackathonInfos.length - 1;
    }

    function signManifestoAndJoinDAO() public payable {
        require(userInfos[msg.sender].joined == false, "User already joined");
        require(msg.value == 10 ether, "Must send 10 OP to join DAO");
        manifesto.sign(); // mints 1 manifesto NFT to the sender
        userInfos[msg.sender].joined = true;
    }

    function createProject(
        address SAFE,
        uint256 hackathonId,
        PrizeDistributionType prizeDistributionType,
        uint256 predictiveValue
    ) public {
        require(hackathonInfos[hackathonId].endTimestamp > block.timestamp, "Hackathon must not have ended");
        require(projectInfos[SAFE].creators.length == 0, "Project already exists");
        require(SAFE != address(0), "SAFE address must be set");
        // ProjectInfo storage projectInfo = ProjectInfo(
        //     SAFE, hackathonId, prizeDistributionType, predictiveValue, 0, [msg.sender], new Task[](0), false
        // );

        ProjectInfo storage projectInfo = projectInfos[SAFE];

        projectInfo.SAFE = SAFE;
        projectInfo.hackathonId = hackathonId;
        projectInfo.prizeDistributionType = prizeDistributionType;
        projectInfo.predictiveValue = predictiveValue;
        projectInfo.prize = 0;
        projectInfo.team.push(msg.sender);
        projectInfo.isCreator[msg.sender] = true;
        projectInfo.creators.push(msg.sender);

        attestProjectCreation(msg.sender, SAFE);

        userInfos[msg.sender].projects.push(SAFE);
    }

    function requestToJoinProject(address SAFE, string memory link) external projectExists(SAFE) {
        projectInfos[SAFE].joinRequests[msg.sender] = link;
    }

    function getJoinRequestLink(address SAFE, address buidler) external view returns (string memory) {
        return projectInfos[SAFE].joinRequests[buidler];
    }

    function approveJoinRequest(address SAFE, address buidler) external projectLive(SAFE) onlyCreator(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        require(
            keccak256(abi.encodePacked(project.joinRequests[buidler])) != keccak256(abi.encodePacked("")),
            "buidler must have requested to join"
        );
        require(!project.isBuidler[buidler], "buidler is already a buidler on this project");
        project.isBuidler[buidler] = true;
        userInfos[buidler].projects.push(SAFE);
        delete project.joinRequests[buidler];
    }

    function createTask(address SAFE, uint256 value, uint256 deadline)
        external
        projectLive(SAFE)
        onlyCreator(SAFE)
        returns (uint256)
    {
        require(value > 0 && value < 6, "Task value must be between 1 and 5");
        require(deadline > block.timestamp, "Deadline must be in the future");
        ProjectInfo storage project = projectInfos[SAFE];
        Task memory task;

        task.taskValue = value;
        task.taskCreator = msg.sender;
        task.taskDeadline = deadline;
        task.taskCompleted = false;
        task.easUID = attestTask(msg.sender, deadline);

        project.tasks.push(task);

        // add task UID to task after attesting

        return project.tasks.length - 1;
    }

    function pickUpTask(address SAFE, uint256 taskId) external projectLive(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        Task storage task = project.tasks[taskId];
        require(!task.taskCompleted, "Task must not be done");
        require(task.taskDeadline > block.timestamp, "Task must not be overdue");
        require(project.isBuidler[msg.sender], "User must be a buidler of the project");
        require(task.pickedUpBy == address(0), "Task already picked up");
        task.pickedUpBy = msg.sender;
    }

    function dropTask(address SAFE, uint256 taskId) external projectLive(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        Task storage task = project.tasks[taskId];
        require(!task.taskCompleted, "Task must not be done");
        require(task.taskDeadline > block.timestamp, "Task must not be overdue");
        require(task.pickedUpBy == msg.sender, "Task must have been picked up by the sender");
        task.pickedUpBy = address(0);
    }

    function approveTaskDone(address SAFE, uint256 taskId, address buidler) external projectLive(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        Task storage task = project.tasks[taskId];

        // get task UID

        require(task.taskCreator == msg.sender, "Approver must be the creator of the task");
        require(!task.taskCompleted, "Task must not be done");
        require(task.taskDeadline > block.timestamp, "Task must not be overdue");
        require(task.pickedUpBy == buidler, "Task must have been picked up by the buidler");

        attestApproveTaskDone(msg.sender, buidler, task.easUID);

        merit.mint(buidler, task.taskValue);
        task.taskCompleted = true;
    }

    function invest(address SAFE) external payable {
        //projectLive(SAFE)?
        require(msg.value > 0, "Must send more than 0 OP");
        require(userInfos[msg.sender].joined, "Sender must have joined the DAO");
        ProjectInfo storage project = projectInfos[SAFE];
        if (project.investors[msg.sender] == 0) project.team.push(msg.sender);
        project.investors[msg.sender] += msg.value;
        project.totalInvestment += msg.value;
        // transfer(SAFE, msg.value); //TODO?
    }

    // function closeProject(address SAFE) external onlyCreator(SAFE) {
    //     ProjectInfo storage project = projectInfos[SAFE];
    //     // _addMerit(project, msg.sender, 3); // reward creator with 3 merits for finishing project
    //     uint256 DAOShare = (project.prize * DAOSharePercentage) / 100;
    //     uint256 teamShare = project.prize - DAOShare;

    //     // send DOA share to DAOPrizePool
    //     prizePool.send(DAOShare); //TODO: safer? OZ Address?

    //     // send team share to creators, buidlers and investors
    //     for (uint256 i = 0; i < project.team.length; i++) {
    //         uint256 memberShare = project.investors[project.team[i]] / project.totalInvestment
    //             + project.merits[project.team[i]] / project.totalMerits; //TODO get it right :)
    //         address payable teamMember = payable(project.team[i]);
    //         teamMember.send(memberShare);
    //     }

    //     project.closed = true;
    // }

    function withdraw(address SAFE) external projectClosed(SAFE) {
        ProjectInfo storage project = projectInfos[SAFE];
        require(project.prize > 0, "Project must have a prize");
        if (userInfos[msg.sender].userType == UserType.INVESTOR) {
            // _withdrawInvestor(SAFE);
        } else if (userInfos[msg.sender].userType == UserType.BUIDLER) {
            // _withdrawBuidler(SAFE);
        } else {
            // _withdrawCreator(SAFE);
        }
    }

    function withdraw() external {
        require(userInfos[msg.sender].userType != UserType(0), "User has not joined the DAO");
        uint256 amount = (merit.balanceOf(msg.sender) / merit.totalSupply()) * address(this).balance; // ?
    }

    /*
     *     Helper functions
     */
    function isUserInDao(address _user) public view returns (bool) {
        return userInfos[_user].joined == true;
    }
}
